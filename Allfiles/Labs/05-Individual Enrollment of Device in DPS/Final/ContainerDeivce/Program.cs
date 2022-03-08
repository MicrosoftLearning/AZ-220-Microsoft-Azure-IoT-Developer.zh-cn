// Copyright (c) Microsoft. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for full
// license information.

// New Features:
//
// * The Program.ProvisionDevice method contains the logic for registering the
//   device via DPS and verifying the device is still authorized to connect.
// * The Program.SendDeviceToCloudMessagesAsync method sends the telemetry as
//   Device-to-Cloud messages to Azure IoT Hub.
// * The EnvironmentSensor class contains the logic for generating the simulated
//   sensor readings for Temperature, Humidity, Pressure, Latitude, and Longitude.

using Microsoft.Azure.Devices.Client;
using Microsoft.Azure.Devices.Provisioning.Client;
using Microsoft.Azure.Devices.Provisioning.Client.Transport;
using Microsoft.Azure.Devices.Shared;
using System;
using System.Text;
using System.Threading.Tasks;
using Newtonsoft.Json;

namespace ContainerDevice
{
    class Program
    {
        // Azure Device Provisioning Service (DPS) ID Scope
        private static string dpsIdScope = "";
        // Registration ID
        private static string registrationId = "";
        // Individual Enrollment Primary Key
        private const string individualEnrollmentPrimaryKey = "";
        // Individual Enrollment Secondary Key
        private const string individualEnrollmentSecondaryKey = "";

        private const string GlobalDeviceEndpoint = "global.azure-devices-provisioning.net";

        private static int telemetryDelay = 1;

        private static DeviceClient deviceClient;

        // Although the Main method in this application serves a similar purpose
        // to the Main method of the CaveDevice application that you created in
        // a previous lab, it is a little more complex. In the CaveDevice app,
        // you used a device connection string to directly connect to an IoT
        // Hub, this time you need to first provision the device (or, for
        // subsequent connections, confirm the device is still provisioned),
        // then retrieve the appropriate IoT Hub connection details.
        public static async Task Main(string[] args)
        {
            // To connect to DPS, you not only require the dpsScopeId and the
            // GlobalDeviceEndpoint (defined in the variables), you also need to
            // specify the following:
            //
            // * security - the method used for authenticating the enrollment.
            //   In the lab you configured the individual enrollment to use
            //   symmetric keys, therefore the SecurityProviderSymmetricKey is
            //   the logical choice. As you might expect, there are variants of
            //   the providers that support X.509 and TPM as well.
            //
            // * transport - the transport protocol used by the provisioned
            //   device. In this instance, the AMQP handler was chosen
            //   (ProvisioningTransportHandlerAmqp). Of course, HTTP and MQTT
            //   handlers are also available.
            using (var security =
                new SecurityProviderSymmetricKey(registrationId,
                                                 individualEnrollmentPrimaryKey,
                                                 individualEnrollmentSecondaryKey))
            using (var transport =
                new ProvisioningTransportHandlerAmqp(TransportFallbackType.TcpOnly))
            {
                // Once the security and transport variables are populated, you
                // create an instance of the ProvisioningDeviceClient. You will
                // use this instance to register the device and create a
                // DeviceClient in the ProvisionDevice method.
                ProvisioningDeviceClient provClient =
                    ProvisioningDeviceClient.Create(GlobalDeviceEndpoint, dpsIdScope, security, transport);

                using (deviceClient = await ProvisionDevice(provClient, security))
                {
                    // The remainder of the Main method uses the device
                    // client a little differently than you did in the
                    // CaveDevice - this time you explicitly open the device
                    // connection so that the app can use device twins (more on
                    // this in the next exercise), and then call the
                    // SendDeviceToCloudMessagesAsync method to start sending
                    // telemetry.
                    await deviceClient.OpenAsync().ConfigureAwait(false);

                    // The SetDesiredPropertyUpdateCallbackAsync method is used
                    // to set up the DesiredPropertyUpdateCallback event handler
                    // to receive device twin desired property changes. This
                    // code configures deviceClient to call a method named
                    // OnDesiredPropertyChanged when a device twin property
                    // change event is received.
                    await deviceClient
                        .SetDesiredPropertyUpdateCallbackAsync(
                            OnDesiredPropertyChanged, null)
                        .ConfigureAwait(false);

                    // This code calls the DeviceTwin.GetTwinAsync method to
                    // retrieve the device twin for the simulated device. It
                    // then accesses the Properties.Desired property object to
                    // retrieve the current Desired State for the device, and
                    // passes that to the OnDesiredPropertyChanged method that
                    // will configure the simulated devices telemetryDelay variable.
                    // Notice, this code reuses the OnDesiredPropertyChanged
                    // method that was already created for handling
                    // OnDesiredPropertyChanged events.This helps keep the code
                    // that reads the device twin desired state properties and
                    // configures the device at startup in a single place.The
                    // resulting code is simpler and easier to maintain.
                    var twin = await deviceClient
                        .GetTwinAsync()
                        .ConfigureAwait(false);
                    await OnDesiredPropertyChanged(twin.Properties.Desired, null);

                    // Start reading and sending device telemetry
                    Console.WriteLine("Start reading and sending device telemetry...");
                    await SendDeviceToCloudMessagesAsync();

                    // Finally, the device client is closed.
                    await deviceClient.CloseAsync().ConfigureAwait(false);
                }
            }
        }

        // This method receives the the provisioning device client and security
        // instances created earlier.
        private static async Task<DeviceClient> ProvisionDevice(
            ProvisioningDeviceClient provisioningDeviceClient,
            SecurityProviderSymmetricKey security)
        {
            // The provisioningDeviceClient.RegisterAsync()
            // is called, which returns a DeviceRegistrationResult instance.
            // This result contains a number of properties including the DeviceId,
            // AssignedHub and the Status.
            var result = await provisioningDeviceClient
                            .RegisterAsync()
                            .ConfigureAwait(false);
            Console.WriteLine($"ProvisioningClient AssignedHub: {result.AssignedHub}; DeviceID: {result.DeviceId}");

            // The method then checks to ensure that the provisioning status has
            // been set and throws an exception if the device is not Assigned.
            // Other possible results here include Unassigned, Assigning,
            // Failed and Disabled.
            if (result.Status != ProvisioningRegistrationStatusType.Assigned)
            {
                throw new Exception($"DeviceRegistrationResult.Status is NOT 'Assigned'");
            }

            // The DeviceAuthenticationWithRegistrySymmetricKey class simplifies
            // the creation of an IoT Hub connection string using the device
            // ID and the Primary Symmetric Key
            var auth = new DeviceAuthenticationWithRegistrySymmetricKey(
                result.DeviceId,
                security.GetPrimaryKey());

            // Finally, a DeviceClient instance is returned that is connected
            // to the desired IoT Hub, using the authentication created above,
            // and using the AMQP protocol.
            return DeviceClient.Create(result.AssignedHub, auth, TransportType.Amqp);
        }

        // The SendDeviceToCloudMessagesAsync method is very similar to what you
        // created in the CaveDevice application. It creates an instance of the
        // EnvironmentSensor class (this one also returns pressure and location
        // data), builds a message and sends it. Notice that instead of a fixed
        // delay within the method loop, the delay is calculated by using the
        // telemetryDelay variable: await Task.Delay(telemetryDelay * 1000);.
        private static async Task SendDeviceToCloudMessagesAsync()
        {
            var sensor = new EnvironmentSensor();

            while (true)
            {
                var currentTemperature = sensor.ReadTemperature();
                var currentHumidity = sensor.ReadHumidity();
                var currentPressure = sensor.ReadPressure();
                var currentLocation = sensor.ReadLocation();

                var messageString = CreateMessageString(currentTemperature,
                                                        currentHumidity,
                                                        currentPressure,
                                                        currentLocation);

                var message = new Message(Encoding.ASCII.GetBytes(messageString));

                // Add a custom application property to the message.
                // An IoT hub can filter on these properties without access to
                // the message body.
                message.Properties.Add("temperatureAlert", (currentTemperature > 30) ? "true" : "false");

                // Send the telemetry message
                await deviceClient.SendEventAsync(message);
                Console.WriteLine("{0} > Sending message: {1}", DateTime.Now, messageString);

                // Use the telemetryDelay property to perform a delay before
                // the next Telemetry reading
                await Task.Delay(telemetryDelay * 1000);
            }
        }

        private static string CreateMessageString(double temperature, double humidity, double pressure, EnvironmentSensor.Location location)
        {
            // Create an anonymous object that matches the data structure we
            // wish to send
            var telemetryDataPoint = new
            {
                temperature = temperature,
                humidity = humidity,
                pressure = pressure,
                latitude = location.Latitude,
                longitude = location.Longitude
            };
            var messageString = JsonConvert.SerializeObject(telemetryDataPoint);

            // Create a JSON string from the anonymous object
            return JsonConvert.SerializeObject(telemetryDataPoint);
        }

        // The OnDesiredPropertyChanged event handler accepts a desiredProperties
        // parameter of type TwinCollection.
        private static async Task OnDesiredPropertyChanged(
            TwinCollection desiredProperties,
            object userContext)
        {
            Console.WriteLine("Desired Twin Property Changed:");
            Console.WriteLine($"{desiredProperties.ToJson()}");

            // Read the desired Twin Properties
            if (desiredProperties.Contains("telemetryDelay"))
            {
                // Notice that if the value of the desiredProperties parameter
                // contains telemetryDelay (a device twin desired property), the
                // code will assign the value of the device twin property to the
                // telemetryDelay variable. You may recall that the
                // SendDeviceToCloudMessagesAsync method includes a Task.Delay
                // call that uses the telemetryDelay variable to set the delay
                // time between messages sent to IoT hub.
                string desiredTelemetryDelay = desiredProperties["telemetryDelay"];
                if (desiredTelemetryDelay != null)
                {
                    telemetryDelay = int.Parse(desiredTelemetryDelay);
                }
                // if desired telemetryDelay is null or unspecified, don't change it
            }

            // The next block of code is used to report the current state of the
            // device back up to Azure IoT Hub. This code calls the DeviceClient.
            // UpdateReportedPropertiesAsync method and passes it a
            // TwinCollection that contains the current state of the device
            // properties.
            // This is how the device reports back to IoT Hub that it received
            // the device twin desired properties changed event, and has now
            // updated its configuration accordingly.
            // Note that it  reports what the properties are now set to, not an
            // echo of the desired properties. In the case where the reported
            // properties sent from the device are different than the desired
            // state that the device received, IoT Hub will maintain an accurate
            // Device Twin that reflects the state of the device.
            var reportedProperties = new TwinCollection();
            reportedProperties["telemetryDelay"] = telemetryDelay.ToString();
            await deviceClient
                .UpdateReportedPropertiesAsync(reportedProperties)
                .ConfigureAwait(false);
            Console.WriteLine("Reported Twin Properties:");
            Console.WriteLine($"{reportedProperties.ToJson()}");
        }
    }

    internal class EnvironmentSensor
    {
        // Initial telemetry values
        double minTemperature = 20;
        double minHumidity = 60;
        double minPressure = 1013.25;
        double minLatitude = 39.810492;
        double minLongitude = -98.556061;
        Random rand = new Random();

        internal class Location
        {
            internal double Latitude;
            internal double Longitude;
        }

        internal double ReadTemperature()
        {
            return minTemperature + rand.NextDouble() * 15;
        }
        internal double ReadHumidity()
        {
            return minHumidity + rand.NextDouble() * 20;
        }
        internal double ReadPressure()
        {
            return minPressure + rand.NextDouble() * 12;
        }
        internal Location ReadLocation()
        {
            return new Location { Latitude = minLatitude + rand.NextDouble() * 0.5, Longitude = minLongitude + rand.NextDouble() * 0.5 };
        }
    }
}

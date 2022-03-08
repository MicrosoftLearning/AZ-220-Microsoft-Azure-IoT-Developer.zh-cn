// Copyright (c) Microsoft. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for full license information.

// New Features:
// * CheeseCaveSimulator class - (replaces EnvironmentSensor) rather than just
//   generating telemetry, this class also simulates a running cheese cave
//   environment that is impacted by the operation of a cooling fan.

using System;
using Microsoft.Azure.Devices.Client;
using Microsoft.Azure.Devices.Shared;
using Newtonsoft.Json;
using System.Text;
using System.Threading.Tasks;
using Newtonsoft.Json.Linq;
using static CheeseCaveDevice.CheeseCaveSimulator;

namespace CheeseCaveDevice
{
    class Program
    {
        // Interval at which telemetry is sent to the cloud.
        const int intervalInMilliseconds = 5000;

        // Global variables.
        private static DeviceClient deviceClient;

        private static CheeseCaveSimulator cheeseCave;

        // The device connection string to authenticate the device with your IoT hub.
        private readonly static string deviceConnectionString = "<your device connection string>";

        // This application is very similar to the simulated device applications
        // that you have worked on in the preceding labs. This version uses
        // symmetric Key authentication, sends both telemetry and logging
        // messages to the IoT Hub, and has a more complex sensor implementation.
        private static async Task Main(string[] args)
        {
            ConsoleHelper.WriteColorMessage("Cheese Cave device app.\n", ConsoleColor.Yellow);

            // Connect to the IoT hub using the MQTT protocol.
            deviceClient = DeviceClient.CreateFromConnectionString(
                deviceConnectionString,
                TransportType.Mqtt);

            // Create an instance of the Cheese Cave Simulator
            cheeseCave = new CheeseCaveSimulator();

            // Create a handler for the direct method call
            // Notice that the SetFanState direct method handler is also set
            // up by this code. As you can see, the SetMethodHandlerAsync
            // method of deviceClient takes the remote method name `"SetFanState"`
            // as an argument, along with the actual local method to call, and a
            // user context object (in this case null)

            // UNCOMMENT register direct method code below here
            await deviceClient.SetMethodHandlerAsync("SetFanState", SetFanState, null);

            // UNCOMMENT register desired property changed handler code below here
            // Get the device twin to report the initial desired properties.
            Twin deviceTwin = await deviceClient.GetTwinAsync();
            ConsoleHelper.WriteGreenMessage("Initial twin desired properties: " + deviceTwin.Properties.Desired.ToJson());

            // Set the device twin update callback.
            await deviceClient.SetDesiredPropertyUpdateCallbackAsync(OnDesiredPropertyChanged, null);

            await SendDeviceToCloudMessagesAsync();
            Console.ReadLine();
        }

        // Async method to send simulated telemetry.
        private static async Task SendDeviceToCloudMessagesAsync()
        {
            while (true)
            {
                var currentTemperature = cheeseCave.ReadTemperature();
                var currentHumidity = cheeseCave.ReadHumidity();

                // Create JSON message.
                var telemetryDataPoint = new
                {
                    temperature = Math.Round(currentTemperature, 2),
                    humidity = Math.Round(currentHumidity, 2)
                };
                var messageString = JsonConvert.SerializeObject(telemetryDataPoint);
                var message = new Message(Encoding.ASCII.GetBytes(messageString));

                // Add custom application properties to the message.
                message.Properties.Add("sensorID", "S1");
                message.Properties.Add("fanAlert", (cheeseCave.FanState == StateEnum.Failed) ? "true" : "false");

                // Send temperature or humidity alerts, only if they occur.
                if (cheeseCave.IsTemperatureAlert)
                {
                    message.Properties.Add("temperatureAlert", "true");
                }
                if (cheeseCave.IsHumidityAlert)
                {
                    message.Properties.Add("humidityAlert", "true");
                }

                Console.WriteLine("Message data: {0}", messageString);

                // Send the telemetry message.
                await deviceClient.SendEventAsync(message);
                ConsoleHelper.WriteGreenMessage("Message sent\n");

                await Task.Delay(intervalInMilliseconds);
            }
        }

        // UNCOMMENT SetFanState method below here
        // This method that runs on the device when the associated remote method,
        // also called SetFanState, is invoked via IoT Hub. Notice that in
        // addition to receiving a MethodRequest instance, it also receives the
        // userContext object that was defined when the direct message callback
        // was registered (in this case it will be null)
        private static Task<MethodResponse> SetFanState(MethodRequest methodRequest, object userContext)
        {
            // The first line of this method determines whether the cheese cave
            // fan is currently in a Failed state - the assumption made by the
            // cheese cave simulator is that once the fan has failed, any
            // subsequent command will automatically fail.
            if (cheeseCave.FanState == StateEnum.Failed)
            {
                // Acknowledge the direct method call with a 400 error message.
                // a JSON string is created with the result property set to Fan
                // Failed
                string result = "{\"result\":\"Fan failed\"}";
                // A new MethodResponse object is then constructed, with the
                // result string encoded into a byte array and an HTTP status
                // code - in this instance, 400 is used which, in the context of
                // a REST API means a generic client-side error has occurred.
                ConsoleHelper.WriteRedMessage("Direct method failed: " + result);
                // As direct method callbacks are required to return a
                // Task<MethodResponse>, a new task is created and returned.
                return Task.FromResult(new MethodResponse(Encoding.UTF8.GetBytes(result), 400));
            }
            else
            {
                // If the fan state is not Failed, the code then proceeds to
                // process the data sent as part of the method request.
                try
                {
                    // The methodRequest.Data property contains the data in the
                    // form of a byte array, so it is first converted to a string.
                    var data = Encoding.UTF8.GetString(methodRequest.Data);

                    // In order to parse the data, the quotes must first be
                    // removed and then the Enum.Parse method is used to find a
                    // matching enum value.
                    data = data.Replace("\"", "");

                    // Parse the payload, and trigger an exception if it's not valid.
                    cheeseCave.UpdateFan((StateEnum)Enum.Parse(typeof(StateEnum), data));
                    ConsoleHelper.WriteGreenMessage("Fan set to: " + data);

                    // Acknowledge the direct method call with a 200 success message.
                    string result = "{\"result\":\"Executed direct method: " + methodRequest.Name + "\"}";
                    return Task.FromResult(new MethodResponse(Encoding.UTF8.GetBytes(result), 200));
                }
                catch
                {
                    // Acknowledge the direct method call with a 400 error message.
                    // Notice that the exception handler creates and returns a
                    // similar error method response to the one created for the
                    // fan failed state.
                    string result = "{\"result\":\"Invalid parameter\"}";
                    ConsoleHelper.WriteRedMessage("Direct method failed: " + result);
                    return Task.FromResult(new MethodResponse(Encoding.UTF8.GetBytes(result), 400));
                }
            }
        }

        // UNCOMMENT OnDesiredPropertyChanged method below here
        private static async Task OnDesiredPropertyChanged(
            TwinCollection desiredProperties,
            object userContext)
        {
            try
            {
                // Update the Cheese Cave Simulator properties
                cheeseCave.DesiredHumidity = desiredProperties["humidity"];
                cheeseCave.DesiredTemperature = desiredProperties["temperature"];
                ConsoleHelper.WriteGreenMessage("Setting desired humidity to " + desiredProperties["humidity"]);
                ConsoleHelper.WriteGreenMessage("Setting desired temperature to " + desiredProperties["temperature"]);

                // Report the properties back to the IoT Hub.
                var reportedProperties = new TwinCollection();
                reportedProperties["fanstate"] = cheeseCave.FanState.ToString();
                reportedProperties["humidity"] = cheeseCave.DesiredHumidity;
                reportedProperties["temperature"] = cheeseCave.DesiredTemperature;
                await deviceClient.UpdateReportedPropertiesAsync(reportedProperties);

                ConsoleHelper.WriteGreenMessage("\nTwin state reported: " + reportedProperties.ToJson());
            }
            catch
            {
                ConsoleHelper.WriteRedMessage("Failed to update device twin");
            }
        }

    }

    // This is an evolution of the EnvironmentSensor class used in earlier labs.
    // The primary difference is the introduction of a fan -  if the fan is On,
    // the temperature and humidity will gradually move towards the desired
    // values, whereas is the fan is Off (or Failed), then the temperature and
    // humidity values will move towards the ambient values. Of interest is the
    // fact that there is a 1% chance that fan will be set to the Failed state
    // when the temperature is read.
    internal class CheeseCaveSimulator
    {
        internal enum StateEnum
        {
            Off,
            On,
            Failed
        }

        // Global constants.
        // Ambient temperature of a southern cave, in degrees F.
        private const double ambientTemperature = 70;
        // Ambient humidity in relative percentage of air saturation.
        private const double ambientHumidity = 99;
        // Acceptable range above or below the desired temp, in degrees F.
        private const double desiredTempLimit = 5;
        // Acceptable range above or below the desired humidity, in percentages.
        private const double desiredHumidityLimit = 10;

        // state variables
        // initial value is set to the ambient value
        private double currentTemperature = ambientTemperature;
        // initial value is set to the ambient value
        private double currentHumidity = ambientHumidity;

        Random rand = new Random();

        internal StateEnum FanState { get; private set; } = StateEnum.Off;

        internal bool IsTemperatureAlert =>
            (currentTemperature > DesiredTemperature + desiredTempLimit) ||
            (currentTemperature < DesiredTemperature - desiredTempLimit);

        internal bool IsHumidityAlert =>
            (currentHumidity > DesiredHumidity + desiredHumidityLimit) ||
            (currentHumidity < DesiredHumidity - desiredHumidityLimit);

        // Initial desired temperature, in degrees F.
        public double DesiredTemperature { get; set; } = ambientTemperature - 10;
        // Initial desired humidity in relative percentage of air saturation.
        public double DesiredHumidity { get; set; } = ambientHumidity - 20;

        public double ReadTemperature()
        {
            // Simulate telemetry.
            double deltaTemperature = Math.Sign(DesiredTemperature - currentTemperature);

            if (FanState == StateEnum.On)
            {
                // If the fan is on the temperature and humidity will be nudged
                // towards the desired values most of the time.
                currentTemperature += (deltaTemperature * rand.NextDouble())
                                      + rand.NextDouble() - 0.5;

                // Randomly fail the fan.
                if (rand.NextDouble() < 0.01)
                {
                    FanState = StateEnum.Failed;
                    ConsoleHelper.WriteRedMessage("Fan has failed");
                }
            }
            else
            {
                // If the fan is off, or has failed, the temperature and humidity
                // will creep up until they reaches ambient values, thereafter
                // fluctuate randomly.
                if (currentTemperature < ambientTemperature - 1)
                {
                    currentTemperature += rand.NextDouble() / 10;
                }
                else
                {
                    currentTemperature += rand.NextDouble() - 0.5;
                }
            }

            return currentTemperature;
        }

        public double ReadHumidity()
        {
            // Simulate telemetry.
            double deltaHumidity = Math.Sign(DesiredHumidity - currentHumidity);

            if (FanState == StateEnum.On)
            {
                // If the fan is on the temperature and humidity will be nudged
                // towards the desired values most of the time.
                currentHumidity += (deltaHumidity * rand.NextDouble())
                                   + rand.NextDouble() - 0.5;

                // Randomly fail the fan.
                if (rand.NextDouble() < 0.01)
                {
                    FanState = StateEnum.Failed;
                    ConsoleHelper.WriteRedMessage("Fan has failed");
                }
            }
            else
            {
                // If the fan is off, or has failed, the temperature and humidity
                // will creep up until they reaches ambient values, thereafter
                // fluctuate randomly.
                if (currentHumidity < ambientHumidity - 1)
                {
                    currentHumidity += rand.NextDouble() / 10;
                }
                else
                {
                    currentHumidity += rand.NextDouble() - 0.5;
                }
            }

            // Check: humidity can never exceed 100%.
            currentHumidity = Math.Min(100, currentHumidity);

            return currentHumidity;
        }

        internal void UpdateFan(StateEnum newState)
        {
            // in a real device, this method would contain logic to start/stop
            // a fan and determine whether it was successful
            FanState = newState;
        }
    }

    internal static class ConsoleHelper
    {
        internal static void WriteColorMessage(string text, ConsoleColor clr)
        {
            Console.ForegroundColor = clr;
            Console.WriteLine(text);
            Console.ResetColor();
        }
        internal static void WriteGreenMessage(string text)
        {
            WriteColorMessage(text, ConsoleColor.Green);
        }

        internal static void WriteRedMessage(string text)
        {
            WriteColorMessage(text, ConsoleColor.Red);
        }
    }
}
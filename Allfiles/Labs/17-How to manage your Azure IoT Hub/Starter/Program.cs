// Copyright (c) Microsoft. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for full license information.

// This application uses the Azure IoT Hub device SDK for .NET
// For samples see: https://github.com/Azure/azure-iot-sdk-csharp/tree/master/iothub/device/samples

// INSERT using statements below here

using System;
using System.Text;
using System.Threading.Tasks;
using Microsoft.Azure.Devices.Client;
using Newtonsoft.Json;

// INSERT namespace below here
namespace CaveDevice
{
    class Program
    {
        // INSERT variables below here
        // Contains methods that a device can use to send messages to and receive from an IoT Hub.
        private static DeviceClient deviceClient;

        // The device connection string to authenticate the device with your IoT hub.
        // Note: in real-world applications you would not "hard-code" the connection string
        // It could be stored within an environment variable, passed in via the command-line or
        // store securely within a TPM module.
        private readonly static string connectionString = "{Your device connection string here}";

        // INSERT Main method below here
        private static void Main(string[] args)
        {
            Console.WriteLine("IoT Hub C# Simulated Device. Ctrl-C to exit.\n");

            // Connect to the IoT hub using the MQTT protocol
            deviceClient = DeviceClient.CreateFromConnectionString(connectionString, TransportType.Mqtt);
            _ = SendDeviceToCloudMessagesAsync();
            Console.ReadLine();
        }

        // INSERT - SendDeviceToCloudMessagesAsync below here
        // Async method to send simulated telemetry
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
                // An IoT hub can filter on these properties without access to the message body.
                message.Properties.Add("temperatureAlert", (currentTemperature > 30) ? "true" : "false");

                // Send the telemetry message
                await deviceClient.SendEventAsync(message);
                Console.WriteLine("{0} > Sending message: {1}", DateTime.Now, messageString);

                // Delay before next Telemetry reading
                await Task.Delay(1000);
            }
        }

        // INSERT CreateMessageString method below here
        private static string CreateMessageString(double temperature, double humidity, double pressure, EnvironmentSensor.Location location)
        {
            // Create an anonymous object that matches the data structure we wish to send
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
    }


    // INSERT EnvironmentSensor class below here
    /// <summary>
    /// This class represents a sensor
    /// real-world sensors would contain code to initialize
    /// the device or devices and maintain internal state
    /// a real-world example can be found here: https://bit.ly/IoT-BME280
    /// </summary>
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
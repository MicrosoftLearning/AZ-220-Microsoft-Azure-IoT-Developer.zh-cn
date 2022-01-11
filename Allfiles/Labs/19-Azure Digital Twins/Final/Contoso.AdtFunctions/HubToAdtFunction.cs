// Copyright (c) Microsoft. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for full license information.
using System;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.EventGrid.Models;
using Microsoft.Azure.WebJobs.Extensions.EventGrid;
using Microsoft.Extensions.Logging;
using Azure.DigitalTwins.Core;
using Azure.Identity;
using System.Net.Http;
using Azure.Core.Pipeline;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System.Text;

namespace Contoso.AdtFunctions
{
    public static class HubToAdtFunction
    {
        //Your Digital Twins URL is stored in an application setting in Azure Functions.
        private static readonly string adtInstanceUrl = Environment.GetEnvironmentVariable("ADT_SERVICE_URL");
        private static readonly HttpClient httpClient = new HttpClient();

        [FunctionName("HubToAdtFunction")]
        public async static void Run([EventGridTrigger] EventGridEvent eventGridEvent, ILogger log)
        {
            log.LogInformation(eventGridEvent.Data.ToString());

            if (adtInstanceUrl == null)
            {
                log.LogError("Application setting \"ADT_SERVICE_URL\" not set");
                return;
            }

            try
            {
                // INSERT authentication code below here
                ManagedIdentityCredential cred = new ManagedIdentityCredential("https://digitaltwins.azure.net");
                DigitalTwinsClient client = new DigitalTwinsClient(new Uri(adtInstanceUrl), cred, new DigitalTwinsClientOptions { Transport = new HttpClientTransport(httpClient) });
                log.LogInformation($"Azure digital twins service client connection created.");

                // INSERT event processing code below here
                if (eventGridEvent != null && eventGridEvent.Data != null)
                {

                    // Read deviceId and temperature for IoT Hub JSON.
                    JObject deviceMessage = (JObject)JsonConvert.DeserializeObject(eventGridEvent.Data.ToString());
                    string deviceId = (string)deviceMessage["systemProperties"]["iothub-connection-device-id"];
                    var fanAlert = (bool)deviceMessage["properties"]["fanAlert"]; // cast directly to a bool
                    var temperatureAlert = deviceMessage["properties"].SelectToken("temperatureAlert") ?? false; // JToken object
                    var humidityAlert = deviceMessage["properties"].SelectToken("humidityAlert") ?? false; // JToken object
                    log.LogInformation($"Device:{deviceId} fanAlert is:{fanAlert}");
                    log.LogInformation($"Device:{deviceId} temperatureAlert is:{temperatureAlert}");
                    log.LogInformation($"Device:{deviceId} humidityAlert is:{humidityAlert}");

                    var bodyJson = Encoding.ASCII.GetString((byte[])deviceMessage["body"]);
                    JObject body = (JObject)JsonConvert.DeserializeObject(bodyJson);
                    log.LogInformation($"Device:{deviceId} Temperature is:{body["temperature"]}");
                    log.LogInformation($"Device:{deviceId} Humidity is:{body["humidity"]}");

                    // INSERT ADT update code below here
                    // Update twin properties
                    var patch = new Azure.JsonPatchDocument();
                    patch.AppendReplace<bool>("/fanAlert", fanAlert); // already a bool
                    patch.AppendReplace<bool>("/temperatureAlert", temperatureAlert.Value<bool>()); // convert the JToken value to bool
                    patch.AppendReplace<bool>("/humidityAlert", humidityAlert.Value<bool>()); // convert the JToken value to bool

                    await client.UpdateDigitalTwinAsync(deviceId, patch);

                    // publish telemetry
                    await client.PublishTelemetryAsync(deviceId, null, bodyJson);
                }
            }
            catch (Exception e)
            {
                log.LogError(e.Message);
            }
        }
    }
}

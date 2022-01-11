using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.Azure.EventHubs;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace Consoto.AdtFunctions
{
    public static class TelemetryFunction
    {
        [FunctionName("TelemetryFunction")]
        public static async Task Run(
            [EventHubTrigger("evh-az220-adt2func", Connection = "ADT_HUB_CONNECTIONSTRING")] EventData[] events,
            [EventHub("evh-az220-func2tsi", Connection = "TSI_HUB_CONNECTIONSTRING")] IAsyncCollector<string> outputEvents,
            ILogger log)
        {
            var exceptions = new List<Exception>();

            foreach (EventData eventData in events)
            {
                try
                {
                    // INSERT check telemetry below here
                    if ((string)eventData.Properties["cloudEvents:type"] == "microsoft.iot.telemetry" &&
                        (string)eventData.Properties["cloudEvents:dataschema"] == "dtmi:com:contoso:digital_factory:cheese_factory:cheese_cave_device;1")
                    {
                        // INSERT TSI Event creation below here
                        // The event is Cheese Cave Device Telemetry
                        string messageBody = Encoding.UTF8.GetString(eventData.Body.Array, eventData.Body.Offset, eventData.Body.Count);
                        JObject message = (JObject)JsonConvert.DeserializeObject(messageBody);

                        var tsiUpdate = new Dictionary<string, object>();
                        tsiUpdate.Add("$dtId", eventData.Properties["cloudEvents:source"]);
                        tsiUpdate.Add("temperature", message["temperature"]);
                        tsiUpdate.Add("humidity", message["humidity"]);

                        var tsiUpdateMessage = JsonConvert.SerializeObject(tsiUpdate);
                        log.LogInformation($"TSI event: {tsiUpdateMessage}");

                        await outputEvents.AddAsync(tsiUpdateMessage);
                    }
                    else
                    {
                        log.LogInformation($"Not Cheese Cave Device telemetry");
                        await Task.Yield();
                    }
                }
                catch (Exception e)
                {
                    // We need to keep processing the rest of the batch - capture this exception and continue.
                    // Also, consider capturing details of the message that failed processing so it can be processed again later.
                    exceptions.Add(e);
                }
            }

            // Once processing of the batch is complete, if any messages in the batch failed processing throw an exception so that there is a record of the failure.

            if (exceptions.Count > 1)
                throw new AggregateException(exceptions);

            if (exceptions.Count == 1)
                throw exceptions.Single();
        }
    }
}

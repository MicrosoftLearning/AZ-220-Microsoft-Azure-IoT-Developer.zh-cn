// Copyright (c) Microsoft. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for full license information.
using Azure;
using Azure.Core.Pipeline;
using Azure.DigitalTwins.Core;
using Azure.Identity;
using Microsoft.Azure.EventGrid.Models;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.EventGrid;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;

namespace Contoso.AdtFunctions
{
    public static class UpdateTwinFunction
    {
        //Your Digital Twins URL is stored in an application setting in Azure Functions.
        private static readonly string adtInstanceUrl = Environment.GetEnvironmentVariable("ADT_SERVICE_URL");
        private static readonly HttpClient httpClient = new HttpClient();

        private static string[] mappedProperties = new string[] {
                                        "/fanAlert",
                                        "/humidityAlert",
                                        "/temperatureAlert"
                                    };


        [FunctionName("UpdateTwinFunction")]
        public async static void Run([EventGridTrigger] EventGridEvent eventGridEvent, ILogger log)
        {
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
                    string twinId = eventGridEvent.Subject.ToString();
                    JObject message = (JObject)JsonConvert.DeserializeObject(eventGridEvent.Data.ToString());

                    log.LogInformation($"Reading event from {twinId}: {eventGridEvent.EventType}: {message["data"]}");

                    // INSERT process Cheese Cave Device events here
                    if (message["data"]["modelId"] != null && (string)message["data"]["modelId"] == "dtmi:com:contoso:digital_factory:cheese_factory:cheese_cave_device;1")
                    {
                        // INSERT Find the device parent model (the Cheese Cave)
                        AsyncPageable<IncomingRelationship> rels = client.GetIncomingRelationshipsAsync(twinId);

                        string parentId = null;
                        await foreach (IncomingRelationship ie in rels)
                        {
                            if (ie.RelationshipName == "rel_has_devices")
                            {
                                parentId = ie.SourceId;
                                break;
                            }
                        }

                        if (parentId == null)
                        {
                            log.LogError($"Unable to find parent for {twinId}");
                        }
                        else
                        {
                            // INSERT Update the parent
                            // Read properties which values have been changed in each operation
                            var patch = new Azure.JsonPatchDocument();

                            foreach (var operation in message["data"]["patch"])
                            {
                                string opValue = (string)operation["op"];
                                if (opValue.Equals("replace"))
                                {
                                    string propertyPath = ((string)operation["path"]);

                                    if (mappedProperties.Contains(propertyPath))
                                    {
                                        var value = operation["value"].Value<bool>();
                                        patch.AppendReplace<bool>(propertyPath, value);
                                        log.LogInformation($"Updating parent {parentId}: {propertyPath} = {value}");
                                    }
                                }

                            }

                            await client.UpdateDigitalTwinAsync(parentId, patch);
                        }
                    }
                    else
                    {
                        log.LogInformation($"Source model is not a Cheese Cave Device: {(message["data"]["modelId"] != null ? (string)message["data"]["modelId"] : "null")}");
                    }
                }
            }
            catch (Exception e)
            {
                log.LogError(e.Message);
            }
        }
    }
}

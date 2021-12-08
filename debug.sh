#!/bin/bash

source env.sh

LOG_ANALYTICS_WORKSPACE_CLIENT_ID=`az monitor log-analytics workspace show --query customerId -g $rgName -n $name --out tsv`

az monitor log-analytics query --workspace $LOG_ANALYTICS_WORKSPACE_CLIENT_ID --analytics-query "ContainerAppConsoleLogs_CL | where ContainerAppName_s == '$containerAppName' | project ContainerAppName_s, Log_s, TimeGenerated | order by TimeGenerated asc" -o tsv

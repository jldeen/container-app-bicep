#!/bin/bash
# This script will run an ARM template deployment to deploy all the
# required resources into Azure.
# Azure CLI (log in)

# Progress Spinner
function spinner { 
   local pid=$!
   local spin='-\|/'
   local i=0
   while kill -0 $pid 2>/dev/null; do
      (( i = (i + 1) % 4 ))
      printf '\b%c' "${spin:i:1}"
      sleep .1
   done
   printf ' \r'
}

# Linebreak carriage return
function linebreak {
   printf ' \n '
}

# Get outputs of Azure Deployment
function getOutput {
   echo $(az deployment sub show --name $rgName --query "properties.outputs.$1.value" --output tsv)
}

# Get the IP address of specified Kubernetes service
function getIp {
   kubectl get services $1 --output jsonpath='{.status.loadBalancer.ingress[0].ip}'
}

# Get the latest version of Kubernetes available in specified location
function getLatestK8s {
   versions=$(az aks get-versions -l $location -o tsv --query="orchestrators[].orchestratorVersion")

   latestVersion=$(printf '%s\n' "${versions[@]}" |
   awk '$1 > m || NR == 1 { m = $1 } END { print m }')

   echo $latestVersion
}

# Get RG name, location, and App Name
source env.sh

# Deploy the infrastructure
az deployment sub create --name $rgName \
   --location $location \
   --template-file ./main.bicep \
   --parameters rgName=$rgName \
   --parameters location=$location \
   --parameters name=$name \
   --parameters administratorLogin=$administratorLogin \
   --parameters administratorPassword=$administratorPassword \
   --output none

# Get outputs
ghostFQDN=$(getOutput 'ghostFQDN')

printf "\nYour app is accessible from http://%s\n" $ghostFQDN

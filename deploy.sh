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

# The name of the resource group to be created. All resources will be place in
# the resource group and start with name.
rgName=$1
rgName=${rgName:-ghostDemo}

# The location to store the meta data for the deployment.
location=$2
location=${location:-eastus}

# Container App Deployment Name
name=$3
name=${name:-ghostDemo}

# mysql root password
rootPassword=$4
rootPassword=${rootPassword:-R00tP@ssW012d}

# mysql password
mysqlPassword=$5
mysqlPassword=${mysqlPassword:-MySq1P@ssw012D}

# Deploy the infrastructure
az deployment sub create --name $rgName \
   --location $location \
   --template-file ./main.bicep \
   --parameters rgName=$rgName \
   --parameters location=$location \
   --parameters name=$name \
   --parameters mysqlRootPassword=$rootPassword \
   --parameters mysqlPassword=$mysqlPassword \
   --output none

# # Get all the outputs
# aksName=$(getOutput 'aksName')
# storageAccountKey=$(getOutput 'storageAccountKey')
# serviceBusEndpoint=$(getOutput 'serviceBusEndpoint')
# storageAccountName=$(getOutput 'storageAccountName')
# cognitiveServiceKey=$(getOutput 'cognitiveServiceKey')
# cognitiveServiceEndpoint=$(getOutput 'cognitiveServiceEndpoint')

# printf "\nYour app is accessible from http://%s\n" $viewerIp
# printf "Zipkin is accessible from http://%s\n\n" $zipkinIp
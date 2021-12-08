#!/bin/bash
# The name of the resource group to be created. All resources will be place in
# the resource group and start with name.

containerAppName=$1
containerAppName=${containerAppName:-ghost}

rgName=$2
rgName=${rgName:-ghostDemo}

# The location to store the meta data for the deployment.
location=$3
location=${location:-eastus}

# Container App Deployment Name
name=$4
name=${name:-ghostDemo}
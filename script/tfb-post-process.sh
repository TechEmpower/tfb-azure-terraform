#!/bin/bash

set -e

# TFB
sudo docker build -t techempower/tfb /mnt/tfb/FrameworkBenchmarks
sudo docker run \
  --network=host \
  --mount type=bind,source=/mnt/tfb/FrameworkBenchmarks,target=/FrameworkBenchmarks "$TFB_COMMAND" \
  --server-host "$TFB_SERVER_HOST" \
  --client-host "$TFB_CLIENT_HOST" \
  --database-host "$TFB_DATABASE_HOST" \
  --network-mode host \
  --results-name "$TFB_RESULTS_NAME" \
  --results-environment "$TFB_RESULTS_ENVIRONMENT" \
  --results-upload-uri "$TFB_UPLOAD_URI" \
  --quiet

echo "TFB finished"

# Install azure-cli
#sudo apt-get install apt-transport-https lsb-release software-properties-common dirmngr -y

#AZ_REPO=$(lsb_release -cs)
#echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | \
#    sudo tee /etc/apt/sources.list.d/azure-cli.list

#sudo apt-key --keyring /etc/apt/trusted.gpg.d/Microsoft.gpg adv \
#     --keyserver packages.microsoft.com \
#     --recv-keys BC528686B50D79E339D3721CEB3E94ADBE1229CF

#sudo apt-get update
#sudo apt-get install azure-cli

# Copy tfb results to storage
#az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET --tenant $AZURE_TENANT_ID
#az storage blob upload-batch -d $AZURE_STORAGE_CONTAINER_NAME --account-name $AZURE_STORAGE_ACCOUNT_NAME -s "/home/$VM_ADMIN_USERNAME/FrameworkBenchmarks/results"

sudo apt-get -y install zip

zip -r results.zip /mnt/tfb/FrameworkBenchmarks/results

curl \
  -i -v \
  -X POST \
  --header "Content-Type: application/zip" \
  --data-binary @results.zip \
  $TFB_UPLOAD_URI

sleep 5

# Trigger teardown
#curl -X POST -d "" "$AZURE_TEARDOWN_TRIGGER_URL"


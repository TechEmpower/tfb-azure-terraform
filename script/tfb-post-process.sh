#!/bin/bash

set -e

# Citrine's latest commit
if [ "$TFB_USE_LATEST_CITRINE_COMMIT" = true ]; then
  TFB_COMMIT_HASH=$(curl https://tfb-status.techempower.com/last-seen-commit?environment=Citrine)
  echo "Using Citrine's commit $TFB_COMMIT_HASH"
fi
git -C /mnt/tfb/FrameworkBenchmarks checkout $TFB_COMMIT_HASH

# TFB
sudo docker build -t techempower/tfb /mnt/tfb/FrameworkBenchmarks
sudo docker run \
  --network=host \
  --mount type=bind,source=/mnt/tfb/FrameworkBenchmarks,target=/FrameworkBenchmarks techempower/tfb \
  --server-host "$TFB_SERVER_HOST" \
  --client-host "$TFB_CLIENT_HOST" \
  --database-host "$TFB_DATABASE_HOST" \
  --network-mode host \
  --results-name "$TFB_RESULTS_NAME" \
  --results-environment "$TFB_RESULTS_ENVIRONMENT" \
  --results-upload-uri "$TFB_UPLOAD_URI" \
  --quiet

echo "TFB finished"

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
curl -X POST -d "" "$AZURE_TEARDOWN_TRIGGER_URL"


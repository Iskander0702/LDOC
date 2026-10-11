#!/bin/bash

set -e

echo "Creating directories..."

sudo mkdir -p /var/lib/sources/data
sudo mkdir -p /var/lib/sources/app
sudo mkdir -p /etc/sources

echo "Creating files..."

sudo touch /var/lib/sources/data/sample.txt
sudo touch /var/lib/sources/logs/app.log
sudo touch /etc/sources/config.yaml

echo "Creating completed."

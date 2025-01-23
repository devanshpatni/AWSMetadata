#!/bin/bash

METADATA_URL="http://169.254.169.254/latest/meta-data"   # Metadata Service URL
TOKEN=$(curl -s -X PUT "$METADATA_URL/../api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 3600")  # Generate a session token due to v2 metadata

if [ -z "$TOKEN" ]; then  # Token CHecker
    echo "Failed to retrieve metadata token. Ensure this is an EC2 instance."
    exit 1
fi

# Function for  metadata
metadata() {
    local opt=$1
    curl -s "$METADATA_URL/$opt" -H "X-aws-ec2-metadata-token: $TOKEN" | while read -r key; do
        if [[ $key == */ ]]; then  # for directories in metadata
            metadata "$opt$key"
        else
                local val=$(curl -s "$METADATA_URL/$opt$key" -H "X-aws-ec2-metadata-token: $TOKEN" | jq -Rs .) # Print metadata in JSON
            echo "\"$opt$key\": $val"
        fi
    done
}

read -p "Enter a metadata key to retrive (default = whole data ): " key # Taking input from user for metadata key

if [ -z "$key" ]; then  # Fetch whole metadata and convert in JSON
    maindata="{"  
    maindata+=$(metadata "" | paste -sd, -)
    maindata+="}"
    echo "$maindata" | jq .
else   # Fetch metadata for a specific option
    if curl -s --head "$METADATA_URL/$key" -H "X-aws-ec2-metadata-token: $TOKEN" | grep -q "200 OK"; then # to validate the key's presence 
       val=$(curl -s "$METADATA_URL/$key" -H "X-aws-ec2-metadata-token: $TOKEN" | jq -Rs .)
        echo "{\"$key\": $val"} | jq .
    else
        echo "Invalid metadata key: $key"
        exit 1
    fi
fi

#!/bin/bash

resourceGroupName="rg-ai-poc-v2"
workspaceName="log-ai-poc-v2"
analyticsRetentionDays=365 # 12 months
totalRetentionDays=547   # 18 months

az login

# Get a list of table names
tableNames=$(az monitor log-analytics workspace table list \
    --resource-group "$resourceGroupName" \
    --workspace-name "$workspaceName" \
    --query '[].name' \
    -o tsv)

IFS=$'\n' # Set Internal Field Separator to newline to handle table names correctly

for tableName in $(echo "$tableNames" | tr -d '\r'); do
    # Skip tables that are not meant to be updated this way
    if [[ "$tableName" == *_SRCH ]] || [[ "$tableName" == *_RST ]]; then
        echo "Skipping non-configurable table: $tableName"
        continue
    fi

    echo "Configuring table: $tableName"
    az monitor log-analytics workspace table update \
        --resource-group "$resourceGroupName" \
        --workspace-name "$workspaceName" \
        --name "$tableName" \
        --retention-time "$analyticsRetentionDays" \
        --total-retention-time "$totalRetentionDays" --no-wait > /dev/null 2>&1
    if [ $? -eq 0 ]; then # Check the exit code of the az command
        echo "Successfully updated $tableName."
    else
        echo "Failed to update $tableName."
    fi
done
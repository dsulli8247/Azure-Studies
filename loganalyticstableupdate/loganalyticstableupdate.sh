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

for tableName in $tableNames; do
    echo "Configuring table: $tableName"
    az monitor log-analytics workspace table update \
        --resource-group "$resourceGroupName" \
        --workspace-name "$workspaceName" \
        --name "$tableName" \
        --retention-time "$analyticsRetentionDays" \
        --total-retention-time "$totalRetentionDays" --no-wait
    if [ $? -eq 0 ]; then
        echo "Successfully updated $tableName."
    else
        echo "Failed to update $tableName."
    fi
done
LOCATION=westus
APP_NAME=azvnettest
VNET_NAME=${APP_NAME}-vnet
GROUP_NAME=${APP_NAME}-Group
CLUSTER_NAME=${APP_NAME}-Cluster
IP_NAME=${APP_NAME}-IP
SERVER_NAME=${APP_NAME}.$LOCATION.cloudapp.azure.com

VNET_ID=$(az network vnet show --resource-group $GROUP_NAME --name $VNET_NAME --query id -o tsv)

SP_ID=$(az ad sp show --id http://${APP_NAME}-sp --query appId --output tsv)

az role assignment create --assignee $SP_ID --scope $VNET_ID --role Owner

SUBNET_ID=$(az network vnet subnet show --resource-group $GROUP_NAME --vnet-name $VNET_NAME --name ${VNET_NAME}-subnet --query id -o tsv)

LOAD_BALANCER_RESOURCE_GROUP=$(az aks show --resource-group $GROUP_NAME --name $CLUSTER_NAME --query nodeResourceGroup -o tsv)

CLUSTER_CLIENT_ID=$(az aks show --name $CLUSTER_NAME --resource-group $GROUP_NAME --query servicePrincipalProfile.clientId -o tsv)
# az role assignment create --role "Network Contributor" --assignee $CLUSTER_CLIENT_ID --resource-group $LOAD_BALANCER_RESOURCE_GROUP
az role assignment create --role "Owner" --assignee $CLUSTER_CLIENT_ID --resource-group $LOAD_BALANCER_RESOURCE_GROUP

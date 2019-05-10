LOCATION=westus
APP_NAME=azvnettest
VNET_GROUP_NAME=${APP_NAME}-vnet
GROUP_NAME=${APP_NAME}-Group
CLUSTER_NAME=${APP_NAME}-Cluster
IP_NAME=${APP_NAME}-IP
SERVER_NAME=${APP_NAME}.$LOCATION.cloudapp.azure.com

kubectl config use-context $CLUSTER_NAME

LOAD_BALANCER_RESOURCE_GROUP=$(az aks show --resource-group $GROUP_NAME --name $CLUSTER_NAME --query nodeResourceGroup -o tsv)
LOAD_BALANCER_IP=$(az network public-ip show --resource-group $LOAD_BALANCER_RESOURCE_GROUP --name $IP_NAME --query ipAddress --output tsv)
LOAD_BALANCER_HOSTNAME=$(az network public-ip show --resource-group $LOAD_BALANCER_RESOURCE_GROUP --name $IP_NAME --query dnsSettings.fqdn --output tsv)

az aks get-credentials --resource-group $GROUP_NAME --name $CLUSTER_NAME

echo Front-end: $LOAD_BALANCER_HOSTNAME $LOAD_BALANCER_IP

sed -e "s/\$SERVER_NAME/$SERVER_NAME/" -e "s/\$LOAD_BALANCER_IP/$LOAD_BALANCER_IP/"  deploy.yml | kubectl apply -f -

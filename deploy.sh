LOCATION=westus
APP_NAME=azvnettest
VNET_GROUP_NAME=${APP_NAME}-vnet
GROUP_NAME=${APP_NAME}-Group
CLUSTER_NAME=${APP_NAME}-Cluster
IP_NAME=${APP_NAME}-IP
SERVER_NAME=${APP_NAME}.$LOCATION.cloudapp.azure.com

az group create --name $VNET_GROUP_NAME --location $LOCATION

az network vnet create --resource-group $VNET_GROUP_NAME --name $VNET_GROUP_NAME --address-prefixes 10.0.0.0/8 --location $LOCATION
az network vnet subnet create --resource-group $VNET_GROUP_NAME --vnet-name $VNET_GROUP_NAME \
  --name ${VNET_GROUP_NAME}-subnet --address-prefixes 10.1.0.0/16

VNET_ID=$(az network vnet show --resource-group $VNET_GROUP_NAME --name $VNET_GROUP_NAME --query id -o tsv)

SP_PASSWD=$(az ad sp create-for-rbac --name http://${APP_NAME}-sp --skip-assignment --query password -o tsv )
SP_ID=$(az ad sp show --id http://${APP_NAME}-sp --query appId --output tsv)

STATUS=$(az role assignment create --assignee $SP_ID --scope $VNET_ID --role Contributor)

echo $STATUS

kubectl config use-context $CLUSTER_NAME

SUBNET_ID=$(az network vnet subnet show --resource-group $VNET_GROUP_NAME --vnet-name $VNET_GROUP_NAME --name ${VNET_GROUP_NAME}-subnet --query id -o tsv)

az group create --name $GROUP_NAME --location $LOCATION

az aks create  --resource-group $GROUP_NAME --name $CLUSTER_NAME --location $LOCATION \
  --node-count 1 --node-vm-size Standard_B2s --enable-addons monitoring --generate-ssh-keys \
  --network-plugin kubenet \
  --service-cidr 10.23.0.0/16 \
  --dns-service-ip 10.23.0.10 \
  --pod-cidr 10.13.0.0/16 \
  --vnet-subnet-id $SUBNET_ID \
  --service-principal $SP_ID --client-secret $SP_PASSWD

LOAD_BALANCER_RESOURCE_GROUP=$(az aks show --resource-group $GROUP_NAME --name $CLUSTER_NAME --query nodeResourceGroup -o tsv)

az network public-ip create --resource-group $LOAD_BALANCER_RESOURCE_GROUP --name $IP_NAME --allocation-method static --dns-name $APP_NAME

LOAD_BALANCER_IP=$(az network public-ip show --resource-group $LOAD_BALANCER_RESOURCE_GROUP --name $IP_NAME --query ipAddress --output tsv)
LOAD_BALANCER_HOSTNAME=$(az network public-ip show --resource-group $LOAD_BALANCER_RESOURCE_GROUP --name $IP_NAME --query dnsSettings.fqdn --output tsv)

CLUSTER_CLIENT_ID=$(az aks show --name $CLUSTER_NAME --resource-group $GROUP_NAME --query servicePrincipalProfile.clientId -o tsv)
# az role assignment create --role "Network Contributor" --assignee $CLUSTER_CLIENT_ID --resource-group $LOAD_BALANCER_RESOURCE_GROUP
az role assignment create --role "Owner" --assignee $CLUSTER_CLIENT_ID --resource-group $LOAD_BALANCER_RESOURCE_GROUP

az aks get-credentials --resource-group $GROUP_NAME --name $CLUSTER_NAME

echo Front-end: $LOAD_BALANCER_HOSTNAME $LOAD_BALANCER_IP

sed -e "s/\$SERVER_NAME/$SERVER_NAME/" -e "s/\$LOAD_BALANCER_IP/$LOAD_BALANCER_IP/"  deploy.yml | kubectl apply -f -

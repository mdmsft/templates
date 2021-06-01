@description('Azure AD Group in the identified tenant that will be granted the highly privileged cluster-admin role')
param clusterAdminAadGroupObjectId string

@description('Kubernetes version')
param kubernetesVersion string = '1.20.5'

var networkContributorRole = concat(subscription().id, '/providers/Microsoft.Authorization/roleDefinitions/4d97b98b-1d4f-4787-a291-c67834d212e7')
var monitoringMetricsPublisherRole = concat(subscription().id, '/providers/Microsoft.Authorization/roleDefinitions/3913510d-42f4-4e42-8a64-420c390055eb')
var acrPullRole = concat(subscription().id, '/providers/Microsoft.Authorization/roleDefinitions/7f951dda-4ed3-4680-a7ca-43fe172d538d')
var managedIdentityOperatorRole = concat(subscription().id, '/providers/Microsoft.Authorization/roleDefinitions/f1a07417-d97a-45cb-824c-7a7467783830')
var virtualMachineContributorRole = concat(subscription().id, '/providers/Microsoft.Authorization/roleDefinitions/9980e02c-c2be-4d73-94e8-173b1dc7cf3c')
var readerRole = concat(subscription().id, '/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7')

var subRgUniqueString = uniqueString('aks', subscription().subscriptionId, resourceGroup().id)

var nodeResourceGroupName = concat('rg-', clusterName, '-nodepools')
var clusterName = concat('aks-', subRgUniqueString)
var logAnalyticsWorkspaceName = concat('la-', clusterName)
var containerInsightsSolutionName = concat('ContainerInsights(', logAnalyticsWorkspaceName,')')
var defaultAcrName = concat('acraks', subRgUniqueString)

var vNetResourceGroup = split(targetVnetResourceId,'/')[4]
var vnetName = split(targetVnetResourceId,'/')[8]
var vnetNodePoolSubnetResourceId = concat(targetVnetResourceId, '/subnets/snet-clusternodes')
var vnetIngressServicesSubnetResourceId = concat(targetVnetResourceId, '/subnets/snet-cluster-ingressservices')

var agwName = concat('apw-', clusterName)
var apwResourceId = resourceId('Microsoft.Network/applicationGateways', agwName)

var acrPrivateDnsZonesName = 'privatelink.azurecr.io'
var akvPrivateDnsZonesName = 'privatelink.vaultcore.azure.net'

var clusterControlPlaneIdentityName = concat('mi-', clusterName, '-controlplane')

var keyVaultName = concat('kv-', clusterName)

var policyResourceIdAKSLinuxRestrictive = 'providers/Microsoft.Authorization/policySetDefinitions/42b8ef37-b724-4e24-bbc8-7a7708edfe0'
var policyResourceIdEnforceHttpsIngress = 'providers/Microsoft.Authorization/policyDefinitions/1a5b4dca-0b6f-4cf5-907c-56316bc1bf3'
var policyResourceIdEnforceInternalLoadBalancers = 'providers/Microsoft.Authorization/policyDefinitions/3fc4dc25-5baf-40d8-9b05-7fe74c1bc64'
var policyResourceIdRoRootFilesystem = 'providers/Microsoft.Authorization/policyDefinitions/df49d893-a74c-421d-bc95-c663042e5b8'
var policyResourceIdEnforceResourceLimits = 'providers/Microsoft.Authorization/policyDefinitions/e345eecc-fa47-480f-9e88-67dcc122b16'
var policyResourceIdEnforceImageSource = 'providers/Microsoft.Authorization/policyDefinitions/febd0533-8e55-448f-b837-bd0e06f1646'
var policyAssignmentNameAKSLinuxRestrictive = guid(policyResourceIdAKSLinuxRestrictive, resourceGroup().name, clusterName)
var policyAssignmentNameEnforceHttpsIngress = guid(policyResourceIdEnforceHttpsIngress, resourceGroup().name, clusterName)
var policyAssignmentNameEnforceInternalLoadBalancers = guid(policyResourceIdEnforceInternalLoadBalancers, resourceGroup().name, clusterName)
var policyAssignmentNameRoRootFilesystem = guid(policyResourceIdRoRootFilesystem, resourceGroup().name, clusterName)
var policyAssignmentNameEnforceResourceLimits = guid(policyResourceIdEnforceResourceLimits, resourceGroup().name, clusterName)
var policyAssignmentNameEnforceImageSource = guid(policyResourceIdEnforceImageSource, resourceGroup().name, clusterName)

@allowed([
  'AEU1'
  'AEU2'
  'ACU1'
  'AWU1'
  'AWU2'
  'AWCU'
])
param Prefix string

@allowed([
  'I'
  'D'
  'T'
  'U'
  'P'
  'S'
  'G'
  'A'
  'M'
])
param Environment string

@allowed([
  '0'
  '1'
  '2'
  '3'
  '4'
  '5'
  '6'
  '7'
  '8'
  '9'
  '10'
  '11'
  '12'
  '13'
  '14'
  '15'
  '16'
])
param DeploymentID string
param Stage object
param Extensions object
param Global object
param DeploymentInfo object

targetScope = 'managementGroup'

var Deployment = '${Prefix}-${Global.OrgName}-${Global.Appname}-${Environment}${DeploymentID}'


module dp_Deployment_ManagementGroups 'man-MG.bicep' = if (contains(Stage, 'MG') && bool(Stage.MG)) {
  name: 'dp${Deployment}-ManagementGroups'
  params: {
    // move these to Splatting later
    DeploymentID: DeploymentID
    DeploymentInfo: DeploymentInfo
    Environment: Environment
    Extensions: Extensions
    Global: Global
    Prefix: Prefix
    Stage: Stage
  }
  dependsOn: [
    // dp_Deployment_RG
  ]
}


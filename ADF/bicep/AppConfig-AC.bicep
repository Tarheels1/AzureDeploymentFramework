param Deployment string
param DeploymentURI string
param appConfigInfo object
param Global object
param Prefix string
param Environment string
param DeploymentID string
param Stage object

resource OMS 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: '${DeploymentURI}LogAnalytics'
}

var HubRGJ = json(Global.hubRG)

var gh = {
  hubRGPrefix: contains(HubRGJ, 'Prefix') ? HubRGJ.Prefix : Prefix
  hubRGOrgName: contains(HubRGJ, 'OrgName') ? HubRGJ.OrgName : Global.OrgName
  hubRGAppName: contains(HubRGJ, 'AppName') ? HubRGJ.AppName : Global.AppName
  hubRGRGName: contains(HubRGJ, 'name') ? HubRGJ.name : contains(HubRGJ, 'name') ? HubRGJ.name : '${Environment}${DeploymentID}'
}

var HubRGName = '${gh.hubRGPrefix}-${gh.hubRGOrgName}-${gh.hubRGAppName}-RG-${gh.hubRGRGName}'

resource AC 'Microsoft.AppConfiguration/configurationStores@2020-06-01' = {
  name: '${Deployment}-appconf${appConfigInfo.Name}'
  location: resourceGroup().location
  // identity: {
  //   type: 'UserAssigned'
  //   userAssignedIdentities: {
  //     '${resourceId('Microsoft.ManagedIdentity/userAssignedIdentities/', '${Deployment}-uaiKeyVaultSecretsGet')}': {}
  //   }
  // }
  sku: {
    name: appConfigInfo.sku
  }
  properties: {
    publicNetworkAccess: bool(appConfigInfo.publicNetworkAccess) ? 'Enabled' : 'Disabled'
    // encryption: {
    //   keyVaultProperties: {
    //     identityClientId: ''
    //     keyIdentifier: 
    //   }
    // }
  }
}

resource ACDiags 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'service'
  scope: AC
  properties: {
    workspaceId: OMS.id
    logs: [
      {
        category: 'HttpRequest'
        enabled: true
        retentionPolicy: {
          days: 30
          enabled: false
        }
      }
      {
        category: 'Audit'
        enabled: true
        retentionPolicy: {
          days: 30
          enabled: false
        }
      }
    ]
    metrics: [
      {
        timeGrain: 'PT5M'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
  }
}

module vnetPrivateLink 'x.vNetPrivateLink.bicep' = if (contains(appConfigInfo,'privatelinkinfo') && bool(Stage.PrivateLink)) {
  name: 'dp${Deployment}-privatelinkloopAC${appConfigInfo.name}'
  params: {
    Deployment: Deployment
    DeploymentURI: DeploymentURI
    PrivateLinkInfo: appConfigInfo.privateLinkInfo
    providerType: AC.type
    resourceName: AC.name
  }
}

module privateLinkDNS 'x.vNetprivateLinkDNS.bicep' = if (contains(appConfigInfo,'privatelinkinfo') && bool(Stage.PrivateLink)) {
  name: 'dp${Deployment}-registerPrivateDNS${appConfigInfo.name}'
  scope: resourceGroup(HubRGName)
  params: {
    PrivateLinkInfo: appConfigInfo.privateLinkInfo
    providerURL: 'io'
    providerType: AC.type
    resourceName: AC.name
    Nics: contains(appConfigInfo,'privatelinkinfo') && bool(Stage.PrivateLink) ? array(vnetPrivateLink.outputs.NICID) : array('na')
  }
}

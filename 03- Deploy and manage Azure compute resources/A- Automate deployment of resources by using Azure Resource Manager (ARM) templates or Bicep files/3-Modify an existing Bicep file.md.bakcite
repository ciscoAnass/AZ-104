# Modify an existing Bicep file

## A. Why Bicep matters for AZ‑104

Bicep is the **recommended language** for new Azure IaC:

- Easier to read than JSON.
- Compiles to standard ARM template behind the scenes.
- Same capabilities as ARM templates.

For AZ‑104, you must be able to **look at a Bicep file and change it** to meet new requirements:

- Add/change parameters
- Change resource properties (size, tags, SKU…)
- Add new resources or modules
- Use conditions and loops at a basic level

---

## B. Quick Bicep refresher

Basic structure:

```bicep
@description('Name of the storage account.')
param storageAccountName string

@description('Location for all resources.')
param location string = resourceGroup().location

var skuName = 'Standard_LRS'

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: skuName
  }
  kind: 'StorageV2'
  properties: {}
}
```

Keywords:

- `param` – parameter
- `var` – variable
- `resource` – resource definition
- `module` – reference another Bicep/ARM template
- `output` – values returned after deployment

String interpolation:

```bicep
var storageAccountName = 'st${uniqueString(resourceGroup().id)}'
```

---

## C. Common modifications in Bicep

### 1. Add a new parameter

**Scenario**: VM size is hardcoded; you need to make it configurable.

**Before:**

```bicep
resource vm 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: 'vm-prod-01'
  location: resourceGroup().location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2s'
    }
    # ...
  }
}
```

**After:**

```bicep
@description('The size of the virtual machine.')
@allowed([
  'Standard_B2s'
  'Standard_D2s_v3'
])
param vmSize string = 'Standard_B2s'

resource vm 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: 'vm-prod-01'
  location: resourceGroup().location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    # ...
  }
}
```

**Key idea**: use `param` and reference it directly (no `parameters('x')` like in ARM JSON).

---

### 2. Add or change tags

**Scenario**: Company requires `Environment` and `Owner` tags on all resources.

**Before:**

```bicep
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: skuName
  }
  kind: 'StorageV2'
  properties: {}
}
```

**After:**

```bicep
@description('Environment tag, e.g., Dev, Test, Prod.')
param environment string = 'Dev'

@description('Owner of the resource.')
param owner string

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: skuName
  }
  kind: 'StorageV2'
  tags: {
    Environment: environment
    Owner: owner
  }
  properties: {}
}
```

Note: In Bicep, tags are just a dictionary in the `tags` property.

---

### 3. Change SKU or other properties

**Scenario**: You must change the storage account SKU from `Standard_LRS` to `Standard_GRS`.

**Before:**

```bicep
var skuName = 'Standard_LRS'
...
sku: {
  name: skuName
}
```

**After (simplest):**

```bicep
var skuName = 'Standard_GRS'
```

**Better (parameterized):**

```bicep
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
])
param storageSku string = 'Standard_LRS'

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageSku
  }
  kind: 'StorageV2'
  properties: {}
}
```

---

### 4. Add a new resource in Bicep

**Scenario**: Existing file deploys a VNet; you need to add a subnet.

**Before (VNet only):**

```bicep
param location string = resourceGroup().location

resource vnet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: 'vnet-main'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
  }
}
```

**After (add subnet as a child resource):**

```bicep
resource vnet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: 'vnet-main'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'subnet-apps'
        properties: {
          addressPrefix: '10.0.1.0/24'
        }
      }
    ]
  }
}
```

Or as a separate resource:

```bicep
resource subnetApps 'Microsoft.Network/virtualNetworks/subnets@2023-04-01' = {
  name: 'vnet-main/subnet-apps'
  properties: {
    addressPrefix: '10.0.1.0/24'
  }
}
```

Bicep automatically works out dependencies because the subnet name references the VNet name (`vnet-main`).

---

### 5. Use variables for reused values

**Scenario**: Resource name expression is used multiple times.

**Before:**

```bicep
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: 'st${uniqueString(resourceGroup().id)}'
  location: location
  # ...
}

output storageAccountName string = 'st${uniqueString(resourceGroup().id)}'
```

**After:**

```bicep
var storageAccountName = 'st${uniqueString(resourceGroup().id)}'

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  # ...
}

output storageAccountName string = storageAccountName
```

**Benefits**:

- Less duplication
- Easier to reason about final names
- Easier to modify later

---

## D. Conditions and loops (basic understanding)

### 1. Conditional deployment (`if`)

**Scenario**: Deploy diagnostic settings only when `deployDiagnostics` is true.

```bicep
param deployDiagnostics bool = true

resource diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (deployDiagnostics) {
  name: 'diag-settings'
  scope: storageAccount
  properties: {
    # ...
  }
}
```

- If `deployDiagnostics` is `false`, the resource is not created.
- This is the Bicep equivalent of ARM’s `condition` property.

### 2. Loops (`for`) – simple overview

You might see **loops** for repeated resources.

Example: create multiple subnets from a list.

```bicep
param subnetNames array = [
  'subnet-apps'
  'subnet-db'
]

resource vnet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: 'vnet-main'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      for (name, i) in subnetNames: {
        name: name
        properties: {
          addressPrefix: '10.0.${i}.0/24'
        }
      }
    ]
  }
}
```

You don’t need to master complex loops, but you should recognize the pattern:

- `for` keyword
- Iterating over an `array` parameter
- Generating multiple similar blocks

---

## E. Working with modules

Modules let you **break large files into smaller pieces**.

**Existing module:**

```bicep
param location string = resourceGroup().location

module network './networking.bicep' = {
  name: 'networking'
  params: {
    location: location
  }
}

module compute './compute.bicep' = {
  name: 'compute'
  params: {
    location: location
  }
}
```

### Typical modifications

- Add a new parameter and **pass it to the module**:

```bicep
@description('Environment name.')
param environment string = 'Dev'

module network './networking.bicep' = {
  name: 'networking'
  params: {
    location: location
    environment: environment
  }
}
```

- Change module name (for uniqueness):

```bicep
name: 'networking-prod'
```

- Add an additional module for something like monitoring, security baseline, etc.

**Exam mindset**: When you see `module`, think “this is just another template being called from here”.

---

## F. Outputs

Bicep outputs look like:

```bicep
output storageAccountId string = storageAccount.id
output storageAccountName string = storageAccount.name
```

Common modification: add a new output to return something like IP address, DNS name, or resource ID.

Example:

```bicep
output vmPublicIp string = publicIpResource.properties.ipAddress
```

(use whatever properties exist on the resource)

---

## G. Safe editing tips (Bicep)

- Bicep is **whitespace insensitive**, but indentation helps readability.
- Use correct quotes: single quotes `'` for strings, no trailing commas.
- IntelliSense in VS Code is very helpful when you add/modify properties.
- Bicep automatically infers `dependsOn` from references, so you rarely add `dependsOn` manually (unlike ARM JSON).

---

## H. Exam‑style scenarios

### Scenario 1

> You have a Bicep file that deploys a storage account with hardcoded name and SKU. You must deploy different SKUs per environment without changing the code each time. What should you do?

Correct reasoning:

- Introduce a `param storageSku string` with `@allowed` values.
- Use `storageSku` in the `sku` block.
- Use parameter files or CLI parameters to pass different values per environment.

### Scenario 2

> You must add a tag called `Owner` with value provided at deployment time to an existing Bicep file that deploys a VM.

Steps:

1. Add `param owner string`.
2. Add `tags` block (or extend it) on the VM resource:
   ```bicep
   tags: {
     Owner: owner
   }
   ```

### Scenario 3

> You must optionally deploy a log analytics workspace only when `deployWorkspace` is `true`.

Steps:

1. Add `param deployWorkspace bool = true`.
2. Add `if (deployWorkspace)` to the workspace resource:
   ```bicep
   resource law 'Microsoft.OperationalInsights/workspaces@2021-06-01' = if (deployWorkspace) {
     name: 'law-${uniqueString(resourceGroup().id)}'
     location: location
     properties: { }
   }
   ```

---

## I. Summary

To modify an existing Bicep file:

- Use **`param`** to make values configurable.
- Use **`var`** to avoid repeating expressions.
- Update **resource blocks** (type, name, location, sku, tags, properties).
- Add **modules** for structure and reuse.
- Use `if` for **conditional** deployments and `for` for **loops**.
- Add **outputs** for important values.

If you are comfortable doing the same logical changes in both **ARM JSON** and **Bicep**, you are exactly where AZ‑104 wants you to be.
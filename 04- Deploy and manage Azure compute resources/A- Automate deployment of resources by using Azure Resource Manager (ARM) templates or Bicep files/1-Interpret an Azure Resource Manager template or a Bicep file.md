# Interpret an Azure Resource Manager (ARM) template or a Bicep file

## A. Big picture – what ARM and Bicep are

### Infrastructure as Code (IaC)

In Azure, **ARM templates** and **Bicep files** are ways to describe infrastructure as code:

- **Declarative**: you describe **what** you want (resources, properties), not step‑by‑step commands.
- **Idempotent**: you can deploy the same file multiple times; Azure just makes reality match the template.
- **Repeatable**: same file → same infrastructure in dev, test, prod.

On the exam, you must be able to **look at a JSON ARM template or Bicep file and understand:**

- What resources will be created
- How names and properties are built (parameters/variables)
- What outputs you get after deployment

---

## B. ARM template structure (JSON)

An ARM template is a JSON document with well‑known **top‑level sections**:

```jsonc
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": { },
  "variables": { },
  "resources": [ ],
  "outputs": { }
}
```

### 1. `$schema`

- URL that tells tools (VS Code, portal editor) how to **validate** the template.
- Not important to memorize the exact URL for the exam, but know it is for **validation & IntelliSense**, not for deployment behavior.

### 2. `contentVersion`

- String like `"1.0.0.0"`.
- You can use it to version your template.
- Azure does **not** enforce a meaning – it’s for humans/processes.

### 3. `parameters`

Used to pass values at deployment time (so you don’t hardcode things).

Structure:

```jsonc
"parameters": {
  "storageAccountName": {
    "type": "string",
    "minLength": 3,
    "maxLength": 24,
    "metadata": {
      "description": "Name of the storage account."
    }
  },
  "location": {
    "type": "string",
    "defaultValue": "[resourceGroup().location]"
  },
  "replicationType": {
    "type": "string",
    "defaultValue": "LRS",
    "allowedValues": [ "LRS", "GRS", "RAGRS", "ZRS" ]
  }
}
```

Common properties:

- **type**: `string`, `int`, `bool`, `array`, `object`, `secureString`, `secureObject`.
- **defaultValue**: used if no value is provided.
- **allowedValues**: restricts user input.
- **minLength / maxLength** (for strings/arrays) or **minValue / maxValue** (for numbers).
- **metadata.description**: friendly text shown in the portal.

**Exam angle**: when you see `parameters`, think **“values I can override per deployment”**.

### 4. `variables`

Variables are **calculated values** used inside the template to avoid repeating logic.

```jsonc
"variables": {
  "storagePrefix": "st",
  "uniqueStorageName": "[toLower(concat(variables('storagePrefix'), uniqueString(resourceGroup().id)))]"
}
```

- Variables **cannot be passed from outside**; they are computed from constants, parameters and built‑in functions.
- ARM functions like `concat()`, `uniqueString()`, `toLower()`, `resourceGroup()`, etc. are used.

**Tip**: If you see `variables('x')` in resources, look into the `variables` section to understand how values are built.

### 5. `resources`

This is the **most important section**: it defines what Azure will deploy.

Simplified example:

```jsonc
"resources": [
  {
    "type": "Microsoft.Storage/storageAccounts",
    "apiVersion": "2023-01-01",
    "name": "[variables('uniqueStorageName')]",
    "location": "[parameters('location')]",
    "sku": {
      "name": "[concat('Standard_', parameters('replicationType'))]"
    },
    "kind": "StorageV2",
    "tags": {
      "Environment": "Prod",
      "Owner": "IT"
    },
    "properties": {
      "accessTier": "Hot"
    }
  }
]
```

Key properties you must recognize:

- **type**: resource type, e.g. `Microsoft.Storage/storageAccounts`.
- **apiVersion**: which API version to use for this resource type.
- **name**: usually a string or an expression built from parameters/variables.
- **location**: region (often uses `parameters('location')` or `resourceGroup().location`).
- **sku**: SKU/tier (e.g. `Standard_LRS`, `B2s`).
- **kind**: additional classification (e.g., `StorageV2`, `BlobStorage`).
- **tags**: key/value pairs for cost management and governance.
- **properties**: settings specific to that resource (access tier, settings, etc.).
- **dependsOn** *(optional)*: list of resource names this resource depends on.

Example with `dependsOn`:

```jsonc
"dependsOn": [
  "[resourceId('Microsoft.Storage/storageAccounts', variables('uniqueStorageName'))]"
]
```

This tells Azure to create the storage account **before** another resource that depends on it.

### 6. `outputs`

Values returned after deployment:

```jsonc
"outputs": {
  "storageAccountName": {
    "type": "string",
    "value": "[variables('uniqueStorageName')]"
  },
  "storageAccountId": {
    "type": "string",
    "value": "[resourceId('Microsoft.Storage/storageAccounts', variables('uniqueStorageName'))]"
  }
}
```

Use outputs to:

- Pass values to other tools/pipelines
- Quickly copy connection info from deployment history

---

## C. Common ARM template functions you will see

You don’t need **all** functions for AZ‑104, but you should be able to recognize the most common ones:

- **String functions**
  - `concat('a', 'b')` → `"ab"`
  - `toLower()`, `toUpper()`
  - `substring()`

- **Deployment / environment functions**
  - `resourceGroup()` → info about current resource group (name, location, id)
  - `subscription()` → subscription details
  - `deployment()` → deployment name, correlationId

- **Resource functions**
  - `resourceId('Microsoft.Storage/storageAccounts', name)`
  - `reference(resourceId(...))` to read properties of an existing resource

- **Unique naming**
  - `uniqueString(resourceGroup().id)` to generate stable but unique suffixes

**Exam pattern**: they show a template snippet and ask:

- *What will be the resulting name?*
- *Why is this expression used?* (e.g. uniqueness across subscriptions/regions)

---

## D. Bicep file structure

Bicep is a **domain‑specific language (DSL)** that compiles to an ARM template. It has:

- Simpler, cleaner syntax
- Same capabilities as ARM templates
- Same deployment engine (Resource Manager)

### Equivalent storage account example (Bicep)

```bicep
@description('Name of the storage account.')
param storageAccountName string

@description('Azure region for all resources.')
param location string = resourceGroup().location

@allowed([
  'LRS'
  'GRS'
  'RAGRS'
  'ZRS'
])
@description('Replication type for the storage account.')
param replicationType string = 'LRS'

var skuName = 'Standard_${replicationType}'

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: skuName
  }
  kind: 'StorageV2'
  tags: {
    Environment: 'Prod'
    Owner: 'IT'
  }
  properties: {
    accessTier: 'Hot'
  }
}

output storageAccountId string = storageAccount.id
```

Key keywords and concepts:

- `param` – parameter
- `var` – variable
- `resource` – resource declaration
- `output` – output value
- **String interpolation** – `"Standard_${replicationType}"` instead of `concat()`
- Built‑in functions like `resourceGroup()`, `subscription()`, etc., same as ARM.

### Ordering

- In Bicep, you can declare `param`, `var`, `resource`, `output` in **any order**.
- In ARM JSON, they must be under their specific top‑level sections.

### Modules (high‑level view)

A **module** lets you call another Bicep file (or ARM template):

```bicep
module networking './networking.bicep' = {
  name: 'networkingModule'
  params: {
    location: location
  }
}
```

You only need a basic idea for AZ‑104: module = **reusable building block**.

---

## E. Mapping ARM template sections to Bicep concepts

| Concept         | ARM Template (JSON)                     | Bicep                     |
|----------------|------------------------------------------|---------------------------|
| Parameter      | `parameters` section                     | `param` keyword           |
| Variable       | `variables` section                      | `var` keyword             |
| Resource       | `resources` array                        | `resource` keyword        |
| Output         | `outputs` section                        | `output` keyword          |
| Functions      | `[...]` expressions                      | Functions / interpolation |
| Modules        | Linked templates / nested deployments    | `module` keyword          |

If you can read one, you can read the other – Bicep is just more compact.

---

## F. How to “read” a template or Bicep file on the exam

When you get a question with a long JSON/Bicep snippet:

1. **Identify parameters**
   - What can be customized?
   - Are there default values or allowed values?

2. **Check variables**
   - How are names and properties derived?
   - Any `uniqueString()` or `concat()` logic that changes final names?

3. **Inspect resources**
   - Look at `type`, `name`, `location`, `sku`, `kind`, and `properties`.
   - Note `dependsOn` or implicit ordering in Bicep.

4. **Look at outputs**
   - What useful values are exposed after deployment?

5. **Translate expressions**
   - E.g., `"[concat('st', uniqueString(resourceGroup().id))]"` → “storage account whose name starts with `st` plus a unique, deterministic suffix.”

---

## G. Simple mental diagram

```
+--------------------- Template / Bicep file ----------------------+
| parameters  --> values provided at deployment                    |
| variables   --> helper values built from parameters/functions    |
| resources   --> actual Azure resources (VM, VNet, Storage, ...)  |
| outputs     --> values returned after deployment                 |
+------------------------------------------------------------------+
```

**Flow:**

1. Parameters resolved → 2. Variables evaluated → 3. Resources created/updated → 4. Outputs calculated.

---

## H. Exam tips

- Be able to recognize:
  - **Where** parameters are defined vs used.
  - How a **resource name** is built.
  - What **type** of resource is being created (`type` in ARM, resource type string in Bicep).
- Know that **Bicep and ARM templates are equivalent** in capability – Bicep just has easier syntax.
- When you see built‑in functions like `resourceGroup()`, `subscription()`, or `uniqueString()`, think about **why** they are used (dynamic location, unique naming, etc.).
- For AZ‑104, you won’t have to write full templates from scratch, but you **must be comfortable reading and understanding them**.
# Modify an existing Azure Resource Manager (ARM) template

## A. What “modify an ARM template” really means

In AZ‑104, “modify an existing ARM template” usually means:

- Add or change **parameters** (for names, locations, SKUs…)
- Add or modify **resource properties** (tags, SKU, size, settings)
- Add a **new resource** or remove one
- Update **outputs**
- Make the template more **reusable** (less hardcoding)

You don’t need to be a full developer. You just need to understand:

> *Where in the JSON do I change something to achieve the desired behavior?*

---

## B. Typical exam‑style modifications

### 1. Add a new parameter instead of hardcoding a value

**Scenario**: Template has storage location hardcoded. You must allow the admin to choose the location during deployment.

**Before:**

```jsonc
"resources": [
  {
    "type": "Microsoft.Storage/storageAccounts",
    "apiVersion": "2023-01-01",
    "name": "stfixedname123",
    "location": "westeurope",
    "sku": {
      "name": "Standard_LRS"
    },
    "kind": "StorageV2",
    "properties": {}
  }
]
```

**After – step by step:**

1. Add a parameter:

```jsonc
"parameters": {
  "location": {
    "type": "string",
    "defaultValue": "[resourceGroup().location]",
    "metadata": {
      "description": "Location for all resources."
    }
  }
}
```

2. Use the parameter in the resource:

```jsonc
"location": "[parameters('location')]"
```

3. Optionally, also parametrize `name` and `sku` if needed.

**Exam idea**: if the answer choice “add a parameter and reference it in the resource” appears, it’s usually the right direction for flexibility.

---

### 2. Add tags to a resource

**Scenario**: Company wants all storage accounts to include `Environment` and `CostCenter` tags.

**Before:**

```jsonc
"tags": {}
```

or tags missing entirely.

**After:**

```jsonc
"tags": {
  "Environment": "Prod",
  "CostCenter": "IT-123"
}
```

To make tags configurable:

```jsonc
"parameters": {
  "environmentTag": {
    "type": "string",
    "defaultValue": "Dev"
  },
  "costCenterTag": {
    "type": "string"
  }
},
...
"tags": {
  "Environment": "[parameters('environmentTag')]",
  "CostCenter": "[parameters('costCenterTag')]"
}
```

---

### 3. Change VM size or SKU

**Scenario**: Template deploys a VM with `Standard_B1s`, but requirement changes to `Standard_D2s_v3`.

**VM resource snippet:**

```jsonc
"hardwareProfile": {
  "vmSize": "Standard_B1s"
}
```

**Modify to:**

```jsonc
"hardwareProfile": {
  "vmSize": "Standard_D2s_v3"
}
```

Better: make it a parameter:

```jsonc
"parameters": {
  "vmSize": {
    "type": "string",
    "defaultValue": "Standard_B2s",
    "allowedValues": [
      "Standard_B2s",
      "Standard_D2s_v3"
    ]
  }
},
...
"hardwareProfile": {
  "vmSize": "[parameters('vmSize')]"
}
```

**Exam note**: if the question mentions “allow different VM sizes for different environments”, think **parameterize vmSize**.

---

### 4. Add a new resource to the template

**Scenario**: Template creates a storage account, and now you must add a **container** or **private endpoint**.

Basic approach:

1. **Copy** a resource example for the new type (from docs, portal, or existing templates).
2. Add it inside the **`resources` array**.
3. Set the **type**, **apiVersion**, **name**, **properties**.
4. Use `dependsOn` if the new resource depends on an existing one.

**Example: Add a container to a storage account**

```jsonc
{
  "type": "Microsoft.Storage/storageAccounts/blobServices/containers",
  "apiVersion": "2023-01-01",
  "name": "[format('{0}/default/appcontainer', variables('uniqueStorageName'))]",
  "dependsOn": [
    "[resourceId('Microsoft.Storage/storageAccounts', variables('uniqueStorageName'))]"
  ],
  "properties": {
    "publicAccess": "None"
  }
}
```

Key points:

- `name` includes the full path: `<storage-account-name>/default/<container-name>`.
- `dependsOn` ensures the storage account exists first.

---

### 5. Use variables to simplify repeated expressions

**Scenario**: Storage account name is built with a long expression repeated multiple times.

**Before:**

```jsonc
"name": "[toLower(concat('st', uniqueString(resourceGroup().id)))]"
...
"outputs": {
  "storageAccountName": {
    "type": "string",
    "value": "[toLower(concat('st', uniqueString(resourceGroup().id)))]"
  }
}
```

**After:**

1. Add a variable:

```jsonc
"variables": {
  "storageAccountName": "[toLower(concat('st', uniqueString(resourceGroup().id)))]"
}
```

2. Use it:

```jsonc
"name": "[variables('storageAccountName')]"
...
"value": "[variables('storageAccountName')]"
```

This reduces errors and makes templates easier to read.

---

## C. Conditions and `dependsOn`

### 1. Using `condition`

You can conditionally deploy a resource.

```jsonc
"parameters": {
  "deployDiagnostics": {
    "type": "bool",
    "defaultValue": true
  }
},
"resources": [
  {
    "condition": "[parameters('deployDiagnostics')]",
    "type": "Microsoft.Insights/diagnosticSettings",
    "apiVersion": "2021-05-01-preview",
    "name": "diagnostics",
    "dependsOn": [
      "[resourceId('Microsoft.Storage/storageAccounts', variables('storageAccountName'))]"
    ],
    "properties": {
      "...": "..."
    }
  }
]
```

- If `deployDiagnostics` is `false`, this resource is skipped.
- This is often used for **optional features** (diagnostics, backup, extra disks, etc).

### 2. `dependsOn`

- Ensures correct order when resources rely on each other.
- The value is an array of **resource IDs or names**.

Simple example:

```jsonc
"dependsOn": [
  "[resourceId('Microsoft.Network/virtualNetworks', 'vnet-main')]",
  "[resourceId('Microsoft.Network/networkInterfaces', 'nic-vm1')]"
]
```

ARM uses built‑in dependency analysis, but `dependsOn` helps when dependencies are not obvious from properties.

---

## D. Parameter files (.parameters.json)

Instead of providing parameters inline in CLI/PowerShell, you can use a **parameter file**:

```jsonc
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "storageAccountName": {
      "value": "stexamaccount01"
    },
    "location": {
      "value": "westeurope"
    },
    "replicationType": {
      "value": "LRS"
    }
  }
}
```

You **do not** change deployment logic in the template; you just provide different values per environment.

On the exam, if they want you to **“reuse the same template in multiple environments with different values”**, a **parameter file** is often part of the answer.

---

## E. Safe editing tips (JSON pitfalls)

When modifying ARM JSON:

- Keep track of:
  - Braces `{}` and brackets `[]`
  - Commas at the end of lines
- JSON **does not support comments**. In docs you see `//`, but in a real file that would break validation unless it’s JSONC (VS Code only).
- Check:
  - No duplicate property names in the same object
  - The `type` and `apiVersion` of resources remain valid

**Practical pattern**:

1. Copy an existing resource block.
2. Paste it.
3. Change only what is needed (name, type, properties).
4. Validate in VS Code or portal editor.

---

## F. Exam‑style scenario examples

### Example 1

> You have a template that deploys a VM in `East US`. You must allow administrators to deploy the VM in any region while using the same template. What should you modify?

Correct reasoning:

- Introduce a **parameter** for location.
- Replace the hardcoded `"eastus"` with the parameter expression.

### Example 2

> You have a template that deploys a storage account without tags. Security policy requires a `Department` tag. How do you enforce this with minimal change?

Answer:

- Add a `Department` parameter or hardcode the tag in the `tags` section.
- Make sure `tags` exist in the resource definition.

### Example 3

> You want to deploy a second storage account using the same template logic. What do you do?

Answer:

- Add a second resource in `resources` with a different name (or parameter).
- Reuse the same variables/parameters if appropriate.

---

## G. Summary

To modify an existing ARM template, focus on:

- **Parameters**: add/change for flexibility.
- **Variables**: simplify and avoid duplication.
- **Resources**: add/update `type`, `name`, `location`, `sku`, `tags`, `properties`, `dependsOn`.
- **Outputs**: expose useful info after deployment.

If you can read a template and confidently answer *“What change should I make here to achieve X?”*, you are in good shape for AZ‑104.
# Deploy resources by using an ARM template or a Bicep file

## A. Core concepts

Both **ARM templates (JSON)** and **Bicep files** are deployed by **Azure Resource Manager**.

Key ideas:

- You always deploy at a **scope**:
  - Resource group
  - Subscription
  - Management group
  - Tenant
- You can deploy using:
  - **Azure portal**
  - **Azure CLI**
  - **Azure PowerShell**
  - (For DevOps) pipelines, GitHub Actions, etc.

For AZ‑104, focus on **resource‑group and subscription** deployments using **portal, CLI, and PowerShell**.

---

## B. Deploying using the Azure portal

### 1. Deploy a custom template (ARM JSON or Bicep)

High‑level steps:

1. **Open the portal** → search for **“Deploy a custom template”**.
2. Choose:
   - **Build your own template in the editor** (paste or edit JSON), or
   - **Load file** (upload a template file).
3. Provide **parameters** (either directly or via a parameters file).
4. Choose:
   - **Subscription**
   - **Resource group** (or create a new one)
   - **Region** (for subscription / tenant level deployments).
5. Click **Review + create** → **Create**.

The portal is great for **one‑off deployments** and for learning how templates behave.

**Exam points:**

- “Deploy a custom template” blade is the key place for manual template deployment.
- Portal shows you parameter fields automatically generated from the template’s `parameters` section.

---

## C. Deploying ARM templates with Azure CLI

### 1. Resource group‑level deployment

Command:

```bash
az deployment group create   --resource-group MyResourceGroup   --template-file main.json   --parameters storageAccountName=stexam01 location=westeurope
```

or with a parameter file:

```bash
az deployment group create   --resource-group MyResourceGroup   --template-file main.json   --parameters @main.parameters.json
```

Important flags:

- `--resource-group` – scope = resource group.
- `--template-file` – path to ARM or Bicep file.
- `--parameters` – inline `name=value` or `@file.json`.

### 2. Subscription‑level deployment

Used to create **resource groups**, **policy assignments**, etc.

```bash
az deployment sub create   --location westeurope   --template-file subscription.json   --parameters param1=value1
```

Key differences:

- Use `az deployment **sub** create`.
- Need a **location** for the deployment record (not for resources themselves).

### 3. Validate template before deployment

```bash
az deployment group what-if   --resource-group MyResourceGroup   --template-file main.json   --parameters @main.parameters.json
```

- Shows **what will change** (add/modify/delete) without actually changing resources.

---

## D. Deploying ARM templates with Azure PowerShell

### 1. Resource group‑level deployment

```powershell
New-AzResourceGroupDeployment `
  -Name StorageDeployment01 `
  -ResourceGroupName MyResourceGroup `
  -TemplateFile .\main.json `
  -TemplateParameterFile .\main.parameters.json
```

Key parameters:

- `-ResourceGroupName` – the target resource group.
- `-TemplateFile` – path to template.
- `-TemplateParameterFile` – path to parameters.

### 2. Subscription‑level deployment

```powershell
New-AzDeployment `
  -Name SubDeployment01 `
  -Location 'westeurope' `
  -TemplateFile .\subscription.json `
  -TemplateParameterFile .\subscription.parameters.json
```

Use **`New-AzDeployment`** (not `New-AzResourceGroupDeployment`) when deploying at subscription scope.

### 3. Validate deployment

```powershell
Test-AzResourceGroupDeployment `
  -ResourceGroupName MyResourceGroup `
  -TemplateFile .\main.json `
  -TemplateParameterFile .\main.parameters.json
```

- `Test-AzResourceGroupDeployment` checks if template is valid and what errors you might get.

---

## E. Deploying Bicep files

### 1. CLI deployment (most common)

```bash
az deployment group create   --resource-group MyResourceGroup   --template-file main.bicep   --parameters storageAccountName=stexam01
```

- Azure CLI **compiles Bicep to JSON** automatically during deployment.
- You use the same `az deployment group create` and `az deployment sub create` commands.

### 2. PowerShell deployment

```powershell
New-AzResourceGroupDeployment `
  -Name FirstBicep `
  -ResourceGroupName MyResourceGroup `
  -TemplateFile .\main.bicep `
  -TemplateParameterFile .\main.bicepparam
```

- PowerShell also calls the Bicep compiler behind the scenes.

### 3. Bicep parameter files (.bicepparam)

Newer deployments can use **Bicep parameter files**:

`main.bicepparam` example:

```bicep
using './main.bicep'

param storageAccountName = 'stexam01'
param location = 'westeurope'
param replicationType = 'LRS'
```

Deploy with CLI:

```bash
az deployment group create   --resource-group MyResourceGroup   --template-file main.bicepparam
```

Note: With `.bicepparam`, you normally point `--template-file` to the parameter file, not the main Bicep.

---

## F. Deployment scopes (important for exam questions)

| Scope         | Example resources                                 | CLI command family          | PowerShell cmdlet          |
|--------------|----------------------------------------------------|-----------------------------|----------------------------|
| Resource group | VMs, storage, VNets, NICs                        | `az deployment group create` | `New-AzResourceGroupDeployment` |
| Subscription | Policy, role assignments, resource groups          | `az deployment sub create`   | `New-AzDeployment`         |
| Management group | Cross‑sub policy, role assignments           | `az deployment mg create`    | `New-AzManagementGroupDeployment` (less common for AZ‑104) |
| Tenant       | Very high‑level objects (AAD, etc.)                | `az deployment tenant create`| `New-AzTenantDeployment`   |

For AZ‑104, you mainly see **resource‑group** and **subscription** levels.

---

## G. Using deployment history

Each deployment (portal, CLI, PowerShell) records a **deployment entry**.

You can:

- See **inputs** (parameters used).
- See **outputs**.
- Download the **exact template** used.
- Troubleshoot failures (error messages, correlation IDs).

Portal steps:

1. Open the **resource group**.
2. On the **Overview** page, click the **Deployments** link.
3. Select a deployment → see its details, template, parameters, outputs.

This is very useful for:

- Debugging deployments.
- Re‑deploying the same template.
- Exporting a template for later use.

---

## H. Common error patterns and troubleshooting hints

You might see questions about failed deployments. Typical causes:

1. **Name already in use**
   - Example: Storage account names must be **globally unique**.
   - Fix: use `uniqueString()` or change the name parameter.

2. **Location mismatch**
   - Deploying resources in regions not allowed by policy.
   - Fix: use a valid `location` value or adjust policy.

3. **Missing permissions**
   - The user does not have required role (e.g., `Contributor`).
   - For templates, you need permission on:
     - Target resources (e.g., `Microsoft.Compute/virtualMachines/write`)
     - `Microsoft.Resources/deployments/*`

4. **Invalid API version**
   - Template uses an obsolete `apiVersion`.
   - Fix: update template to use a supported API version.

Exam questions might ask which action to take when a template fails – **read the error** and think about these common categories.

---

## I. Putting it all together – example workflow

Imagine a simple end‑to‑end process an Azure admin might follow:

1. **Author or obtain a template/Bicep file**
   - From docs, quickstart templates, export from portal, or existing repo.
2. **Create a parameter file** for your environment.
3. **Test locally** with `what-if` (CLI) or `Test-AzResourceGroupDeployment` (PowerShell).
4. **Deploy**:
   - CLI: `az deployment group create ...`
   - PowerShell: `New-AzResourceGroupDeployment ...`
   - Portal: “Deploy a custom template”.
5. **Check deployment**:
   - View deployment history.
   - Confirm resources in the resource group.
   - Review outputs (e.g., connection strings, IDs).

---

## J. Exam tips

- Learn the **key command names**:
  - `az deployment group create`
  - `az deployment sub create`
  - `New-AzResourceGroupDeployment`
  - `New-AzDeployment`
- Recognize **scope** from the command name (group/sub/etc.).
- Understand that Bicep and JSON are deployed using **the same commands**; Bicep is compiled automatically.
- Remember where to go in the **portal**:
  - “Deploy a custom template” for deployments.
  - Resource group **Deployments** blade for history and troubleshooting.

If you can read a question and decide **which deployment method and scope to use**, you are well prepared for this part of AZ‑104.
# Export a deployment as an ARM template or convert an ARM template to a Bicep file

## A. Why exporting and converting matters

As an Azure administrator you often:

- Build resources manually in the **portal** first (for testing).
- Then you want a **template** so you can redeploy consistently.
- Or you have an **ARM template** and want to move to **Bicep**.

AZ‑104 expects you to know:

1. How to **export** templates for existing resources.
2. How to **get templates from deployment history**.
3. How to **convert JSON ARM templates to Bicep**.

---

## B. Export templates from the Azure portal

There are **two main export options**:

1. Export from **resource group or resource** (snapshot of current state).
2. Export from **deployment history** (exact template used).

### 1. Export from a resource group

Use this when:

- Resources were created manually (no template).
- You want a **snapshot** of the current configuration.
- You may want to **select specific resources** to include.

**Steps:**

1. In the portal, go to **Resource groups** → select the resource group.
2. On the **Resources** list, select one or more resources using the checkboxes.
3. Click **Export template** in the toolbar.
4. Portal generates a template:
   - You can view the JSON template.
   - You can download it as a ZIP.
5. Optionally uncheck **Include parameters** if you want to define them manually later.

Result:

- A generated ARM JSON template capturing current configuration.
- Great starting point, but usually needs **clean‑up** (too many properties, some values hardcoded).

### 2. Export from a single resource

Use this when you only want the template for **one resource**.

**Steps:**

1. Open the specific resource (e.g., a storage account).
2. In the left menu, select **Export template**.
3. View/download the template.

This template only includes that resource (and any required child resources).

### 3. Export from deployment history

Use this when:

- The resource group was created using a template.
- You want the **exact template** used during deployment.

**Steps:**

1. Go to the **Resource group**.
2. In the **Deployments** section (on Overview or left menu), click the deployment name.
3. In deployment details, choose **Template**.
4. Download the template and parameters.

Differences from resource‑group export:

- This template is **cleaner and more reusable** (written by a human or a proper IaC tool).
- It may **not** include any changes made **after** the initial deployment.

---

## C. Export templates with Azure CLI

You can export templates using CLI as well.

### 1. From deployment history

Get the template used for a deployment:

```bash
az deployment group export   --resource-group MyResourceGroup   --name MyDeployment   > MyDeployment.json
```

Equivalent commands exist for other scopes:

- `az deployment sub export`
- `az deployment mg export`
- `az deployment tenant export`

This is similar to “export from deployment history” in the portal.

### 2. From a resource group (snapshot)

Some environments still use:

```bash
az group export   --name MyResourceGroup   --output json   > MyResourceGroup.json
```

It generates a template for **all resources** in a resource group (or at least the most common ones). Behavior is similar to export from a resource group in the portal: the template is auto‑generated and may need clean‑up.

---

## D. Export templates with Azure PowerShell

### 1. Export resource group as a template

```powershell
Export-AzResourceGroup `
  -ResourceGroupName MyResourceGroup
```

- Saves an ARM template file in the current directory.
- Captures **all resources** in the resource group by default.

You can also specify:

- A custom path.
- A subset of resources.
- Output format (JSON or Bicep in newer versions).

Example – export as Bicep:

```powershell
Export-AzResourceGroup `
  -ResourceGroupName MyResourceGroup `
  -OutputFormat Bicep `
  -Path "C:\templates\MyResourceGroup.bicep"
```

### 2. Export specific resources

```powershell
$resource = Get-AzResource `
  -ResourceGroupName MyResourceGroup `
  -ResourceName MyVM `
  -ResourceType "Microsoft.Compute/virtualMachines"

Export-AzResourceGroup `
  -ResourceGroupName MyResourceGroup `
  -Resource $resource.ResourceId
```

This exports a template only for the specific resource(s).

---

## E. Converting an ARM template to a Bicep file

There are two main ways:

1. Using the **Bicep CLI** (or `az bicep` wrapper).
2. Using **Visual Studio Code** with Bicep extension.

### 1. Bicep CLI / Azure CLI (`decompile`)

If you have an ARM JSON template `main.json` and want to convert it to Bicep:

**With Bicep CLI directly:**

```bash
bicep decompile main.json
```

- Creates `main.bicep` in the same folder.
- Tries to produce readable Bicep code.
- You may need to manually clean up some parts.

**With Azure CLI wrapper:**

```bash
az bicep decompile   --file main.json
```

Same effect; just uses `az` to call the Bicep CLI.

### 2. Using Visual Studio Code

1. Install **Bicep extension** in VS Code.
2. Open the ARM JSON template (`main.json`).
3. Use **Command Palette** → `Bicep: Decompile into Bicep`.
4. VS Code generates `main.bicep`.

This is convenient when you are browsing templates from portal export and want to move into Bicep.

---

## F. Workflow: from portal resources to clean Bicep

A realistic workflow you may see described in exam questions:

1. **Create resources manually** in the Azure portal (for testing or prototyping).
2. **Export** the template:
   - From resource group or resource → JSON ARM template.
3. **Decompile** the exported JSON to Bicep:
   - `bicep decompile` or VS Code decompile.
4. **Refactor** the Bicep:
   - Add `param` declarations instead of hardcoded values.
   - Use `var` for repeated expressions.
   - Split into `module`s if large.
5. **Deploy** the new Bicep file:
   - CLI: `az deployment group create --template-file main.bicep …`
   - PowerShell: `New-AzResourceGroupDeployment -TemplateFile .\main.bicep …`

---

## G. When to use which export method

| Goal / Scenario                                                     | Best Option                                      |
|---------------------------------------------------------------------|--------------------------------------------------|
| Get a **clean, human‑written** template used earlier               | Export from **deployment history**              |
| Turn **manual portal configuration** into a template               | Export from **resource group/resource**         |
| Automate export for scripts or CI/CD                               | Use **CLI** (`az group export`, `az deployment export`) or **PowerShell** (`Export-AzResourceGroup`) |
| Move from **JSON ARM** to **Bicep**                                | `bicep decompile` / `az bicep decompile` or VS Code decompile |
| Create a **Bicep file directly** from a resource group             | PowerShell `Export-AzResourceGroup -OutputFormat Bicep` |

---

## H. Limitations and clean‑up after export

Exported templates are very useful, but not perfect. Common issues:

1. **Too many properties**
   - Exported templates include many properties you may not normally specify.
   - Good practice: remove unneeded properties to simplify.

2. **Hardcoded values**
   - Names, locations, SKUs, and other values are often **hardcoded**.
   - Convert them to **parameters** and **variables** for reusability.

3. **Missing secrets**
   - For security reasons, secrets (passwords, keys) often **don’t appear** in exported templates.
   - You must re‑add parameters for connection strings, passwords, etc.

4. **Resource limits**
   - Large resource groups (for example more than 200 resources) might not export fully.
   - You might see warnings that some resources couldn’t be exported.

5. **Older API versions**
   - Export may use older API versions.
   - If you run into issues, update `apiVersion` entries to more recent values.

On the exam, if they mention exported templates are **hard to reuse**, look for answers that say:

- “Refactor the template to add parameters and remove hardcoded values.”
- “Convert to Bicep and clean up the code.”

---

## I. Exam tips

- **Export options in portal**:
  - From **resource group** or **resource** → snapshot of current state.
  - From **deployment history** → exact template used.
- **CLI / PowerShell**:
  - `az deployment group export` → from deployment.
  - `az group export` → from resource group.
  - `Export-AzResourceGroup` → from resource group (can output JSON or Bicep).
- **Convert JSON → Bicep**:
  - `bicep decompile main.json`
  - `az bicep decompile --file main.json`
  - VS Code “Decompile into Bicep” command.

If you can describe how to go from **existing resources** to a **clean, reusable Bicep file**, you have mastered this objective for AZ‑104.
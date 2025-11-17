# Create an App Service

## A. What is Azure App Service?

**Azure App Service** is a fully managed PaaS (Platform as a Service) for hosting:

- Web apps (sites, portals)
- REST APIs
- Mobile back ends
- Background jobs (WebJobs)

You don’t manage OS patching, IIS, load balancers, or scaling infrastructure – Azure does this for you. citeturn1search8turn1search5

Every App Service app:

- Runs inside an **App Service plan** (compute resources).
- Has a **default URL** like `https://myapp.azurewebsites.net`.
- Can have **custom domains**, **TLS**, **deployment slots**, and **backup**, depending on the plan tier.

---

## B. Key choices when creating an App Service

When creating a new app, you decide:

1. **Resource group**
   - Logical container for the app, plan, storage, database, etc.

2. **Name**
   - App name must be **globally unique** within `azurewebsites.net`.
   - Name becomes part of the default hostname: `https://<name>.azurewebsites.net`.

3. **Publish type**
   - **Code** – you deploy app code directly (e.g., .NET, Node.js, Java, Python, PHP).
   - **Docker Container** – you deploy a container image from Docker Hub, ACR, etc.

4. **Runtime stack & OS**
   - Example stacks:
     - .NET 8, .NET 6
     - Node.js
     - PHP
     - Java (Tomcat)
     - Python
   - You also choose **Windows** or **Linux**.

5. **Region**
   - Must match (or be close to) where your users and data are.
   - Determines latency and data residency.

6. **App Service plan**
   - You can **reuse an existing plan** or **create a new one**.
   - Determines cost, scaling, and available features. citeturn1search1turn1search5

---

## C. Create an App Service in the Azure portal (step‑by‑step)

1. **Go to portal**
   - Open **portal.azure.com** and sign in.

2. **Start the creation wizard**
   - Click **Create a resource** → search for **App Service** → **Create**.

3. **Basics tab**
   - **Subscription** – select the correct subscription.
   - **Resource group** – new or existing (e.g. `rg-az104-webapps`).
   - **Name** – e.g. `az104-demo-web` (this must be unique).
   - **Publish** – choose **Code** or **Container**.
   - **Runtime stack** – choose e.g. `.NET 8 (LTS)` or `Node 18 LTS`.
   - **Operating system** – **Windows** or **Linux**.
   - **Region** – e.g. *West Europe*.

4. **App Service plan**
   - Select an existing plan or click **Create new**.
   - When creating a new plan, choose OS, region, and tier (for production, usually **Standard or Premium**). citeturn1search1turn1search27

5. **Monitoring (optional but recommended)**
   - Enable **Application Insights** to capture performance and log data.
   - Choose region close to the app.

6. **Review + create**
   - Check the summary and estimated cost.
   - Click **Create**.
   - After deployment, go to the **app resource** and click its **URL** to open the default page.

---

## D. Create an App Service with Azure CLI

The **CLI** is heavily used in real environments and appears in exam scenarios.

```bash
RG="rg-az104-webapps"
LOCATION="westeurope"
PLAN_NAME="asp-az104-weu-s1"
APP_NAME="az104-demo-web-$RANDOM"

# 1. Create resource group
az group create       --name $RG       --location $LOCATION

# 2. Create App Service plan (Standard S1, Linux)
az appservice plan create       --name $PLAN_NAME       --resource-group $RG       --sku S1       --is-linux

# 3. Create a web app (Node.js runtime)
az webapp create       --name $APP_NAME       --resource-group $RG       --plan $PLAN_NAME       --runtime "NODE|18-lts"
```

Notes:

- For Windows, omit `--is-linux` and use .NET runtimes like `"DOTNET|8"`.
- Check available runtimes with `az webapp list-runtimes`.

---

## E. Create an App Service with Bicep (for reading questions)

Simple example to recognize in exam questions:

```bicep
param location string = resourceGroup().location
param planName string
param appName string

resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' existing = {
  name: planName
}

resource webApp 'Microsoft.Web/sites@2022-09-01' = {
  name: appName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'DOTNET|8.0'  // runtime stack on Linux
    }
    httpsOnly: true
  }
  kind: 'app,linux'
}
```

Key things to spot:

- `Microsoft.Web/sites` → App Service (web app).
- `serverFarmId` → link to the App Service plan.
- `httpsOnly: true` → forces HTTPS.
- `siteConfig` → runtime stack and app settings.

---

## F. First deployment options

Once the app exists, you must deploy code or content. App Service supports several methods: citeturn1search5

- **Git / GitHub / Azure Repos**
  - Continuous deployment using GitHub Actions or Azure DevOps.
- **Zip deploy / Run from package**
  - Upload a ZIP file with your app.
- **Local Git**
  - Azure hosts a Git repository; you push code directly.
- **FTP/FTPS**
  - Legacy option, not ideal for modern pipelines.
- **Container images**
  - Use Docker Hub, Azure Container Registry (ACR), or private registry.

Typical AZ‑104 questions may ask you to choose **which deployment option** fits a scenario (e.g., “Use GitHub Actions for CI/CD”).

---

## G. Example: simple zip deploy from CLI

```bash
# Zip code folder
zip -r app.zip .

# Deploy ZIP package
az webapp deploy       --resource-group $RG       --name $APP_NAME       --src-path app.zip       --type zip
```

Or with PowerShell:

```powershell
Publish-AzWebApp -ResourceGroupName $RG -Name $APP_NAME -ArchivePath .\app.zip
```

---

## H. Best practices and exam tips

1. **Use separate resource groups per environment**
   - Example:
     - `rg-web-dev`
     - `rg-web-test`
     - `rg-web-prod`
   - Makes RBAC, cost, and cleanup easier.

2. **Use Standard or higher tiers for production**
   - Needed for backup, autoscale, deployment slots, and SLAs. citeturn1search1turn1search25

3. **Enable HTTPS‑only early**
   - In the portal, under **TLS/SSL settings** or **Configuration**, enforce HTTPS only.

4. **Use managed identity instead of secrets in code**
   - App Service can access Key Vault or other Azure resources using a system‑assigned or user‑assigned managed identity.

5. **Use Application Insights**
   - Turn it on during creation to get request telemetry, failures, and performance metrics.

6. **Naming convention**
   - Include environment and region:
     - `web-portal-prod-weu`
     - `api-orders-test-eus`

7. **Be comfortable reading ARM/Bicep/CLI snippets**
   - Many AZ‑104 questions show you a template snippet and ask what will be created.

If you can confidently create a web app in the portal and with CLI, and you understand how it links to its App Service plan, you’re ready for this part of the exam.

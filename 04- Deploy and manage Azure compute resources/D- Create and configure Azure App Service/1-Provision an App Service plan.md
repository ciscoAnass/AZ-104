# Provision an App Service plan

## A. Concept and exam context

In Azure App Service, **every web app must run inside an App Service plan**.  
The plan defines the compute resources: region, OS, VM size, pricing tier, and scaling capacity. citeturn1search1

Think of it as:

> App Service plan = “web hosting farm” (VMs, region, capacity).  
> App Service (web app/API) = “your application code” that runs on that farm.

Multiple apps can share the same App Service plan. All those apps **share the same VM instances, memory, CPU, and scaling settings**. Scaling the plan scales *all* apps in it. citeturn1search1turn1search9

### Why the exam cares

In AZ‑104 you must be able to:

- Choose the right **pricing tier** and region.
- Decide when to **reuse an existing plan** vs **create a new one**.
- Understand how plans relate to **cost**, **features** (backup, custom domains, deployment slots), and **scaling**.

---

## B. App Service plan building blocks

When you create a plan, you choose:

1. **Region**
   - Physical location of the underlying compute.
   - All apps in the plan run in that region.
   - Latency and data‑residency depend on it.

2. **Operating system**
   - Windows or Linux (container).
   - Some runtimes are only supported on one of them.

3. **Pricing tier / SKU**
   Each tier gives you different features and capacity. Overview: citeturn1search1turn1search27

   - **Free (F1) / Shared (D1)**
     - For dev/testing only.
     - Shared CPU, very limited resources.
     - No custom domain with SSL, no backup, no scaling beyond 1 instance.
   - **Basic (B)**
     - Dedicated VM instances.
     - Custom domains + basic SSL support.
     - No built‑in autoscale, no deployment slots.
   - **Standard (S)**
     - Dedicated VMs with more options.
     - **Autoscale**, **backup & restore**, **deployment slots**, **traffic routing**.
   - **Premium / PremiumV2 / PremiumV3 / PremiumV4**
     - More CPU/RAM, SSD storage, more instances.
     - Better performance and higher limits (more slots, more connections).
     - Support for **per‑app scaling** so a single app can use only part of the plan capacity. citeturn1search20
   - **Isolated / IsolatedV2**
     - Dedicated environment (App Service Environment) for high isolation and compliance.

4. **Instance size and count**
   - Size: e.g., P1v3, P2v3 → more CPU/RAM per instance.
   - Instance count: how many VMs in the plan (affects scale‑out and cost).

### Features that depend on the tier (high‑level)

| Feature                              | Required tier (minimum) |
|-------------------------------------|--------------------------|
| Custom domain + basic TLS/SSL       | Basic                    |
| Deployment slots                    | Standard                 |
| Backup/restore                      | Standard                 |
| Autoscale (scale out)               | Standard                 |
| Per‑app scaling                     | Standard/Premium+        |
| App Service Environment (isolated)  | Isolated                 |

> **Exam hint**: If a question mentions **backup**, **deployment slots**, or **automatic scaling**, think **Standard or higher**.

---

## C. Design decisions: reuse plan or create a new one?

### When to reuse an existing plan

Reuse an App Service plan when:

- The **new app has similar workload** characteristics (CPU/memory) as existing apps.
- You want to **save costs** by sharing the same VMs.
- Same **OS, region, and pricing tier** are acceptable.

Example:

- You already have a `P1v3` plan in *West Europe* with some lightly used apps.
- You need a new internal admin web UI that is low traffic.
- Reusing the existing plan is cheaper than creating a new Premium plan.

### When to create a new plan

Create a **separate** App Service plan when:

- The app must run in a **different region** (e.g., data residency, latency).
- The app needs a **different OS** (Windows vs Linux).
- The app has different **performance or scaling** requirements (e.g., heavy CPU usage and you don’t want it to steal resources from other apps).
- You want **separate cost visibility** and scaling behaviour.

Exam‑style scenario:

- Several production apps share a Standard plan.
- A new app runs heavy background jobs and causes CPU spikes.
- **Solution**: Move that app to its own plan (same tier, different plan) so it can scale independently.

---

## D. Provision an App Service plan in the Azure portal

Steps (typical exam / real‑world flow):

1. **Open the portal**
   - Go to **portal.azure.com** and sign in.
2. **Create a plan**
   - Search for **“App Service plan”** → **Create**.
3. **Basics tab**
   - **Subscription** – choose the subscription.
   - **Resource group** – create or select an existing one (e.g., `rg-web-eu`).
   - **Name** – something descriptive like `asp-prod-weu-p1v3`.
   - **Operating system** – Windows or Linux.
   - **Region** – choose closest to users (e.g., *West Europe*).
4. **SKU and size**
   - Click **Change size**.
   - Pick a tier and instance size, e.g.:
     - `Standard S1` for typical production apps.
     - `Free F1` for quick demos.
   - Decide if you need features like deployment slots or backup (→ choose Standard+).
5. **Review + create**
   - Check the summary for region, OS, tier, and cost estimate.
   - Click **Create**.

Once deployed, you’ll use this plan when creating an App Service (web app). Any app assigned to this plan will run on its VMs and share its scale settings. citeturn1search1

---

## E. Provision an App Service plan using Azure CLI

Basic CLI pattern (run in Cloud Shell or locally):

```bash
# Variables
RG="rg-az104-appservice"
LOCATION="westeurope"
PLAN_NAME="asp-prod-weu-s1"

# 1. Create resource group (if needed)
az group create       --name $RG       --location $LOCATION

# 2. Create an App Service plan (Windows, Standard S1, 2 instances)
az appservice plan create       --name $PLAN_NAME       --resource-group $RG       --location $LOCATION       --sku S1       --is-linux false       --number-of-workers 2
```

Example for a **Linux** plan:

```bash
az appservice plan create       --name asp-linux-weu-p1v3       --resource-group $RG       --location $LOCATION       --sku P1v3       --is-linux true
```

Key switches to remember for AZ‑104:

- `--sku` – tier & size (F1, D1, B1, S1, P1v3, etc.).
- `--is-linux` – whether this plan is Linux.
- `--number-of-workers` – initial instance count.

---

## F. Provision using Bicep (for ARM‑style questions)

You don’t need to be a Bicep expert for AZ‑104, but you should be able to **read** a simple example and recognize properties.

```bicep
param location string = resourceGroup().location
param planName string = 'asp-prod-weu-s1'

resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: planName
  location: location
  sku: {
    name: 'S1'        // tier+size
    tier: 'Standard'
    capacity: 2       // number of instances
  }
  properties: {
    reserved: false   // false = Windows, true = Linux
  }
}
```

In the exam, look for:

- `Microsoft.Web/serverfarms` → App Service plan.
- `sku.name` & `sku.tier` → pricing tier.
- `capacity` → instance count.
- `properties.reserved` → Linux vs Windows.

---

## G. Best practices and exam tips

1. **Plan per workload type**
   - Group **similar apps** into the same plan (same performance profile).
   - Separate noisy apps into their own plan.

2. **Avoid “everything in one plan”**
   - If many unrelated apps share one plan, one misbehaving app can impact all others.

3. **Align region with data and users**
   - Put the plan close to its users and data sources to reduce latency.

4. **Use naming conventions**
   - Include environment, region, tier and OS in the name, e.g.:
     - `asp-prod-weu-win-s1`
     - `asp-dev-us-lnx-f1`

5. **For experiments, use Free/Shared**
   - But remember: these tiers **don’t support** backup, deployment slots, autoscale, or SLAs.

6. **For production, start at least at Standard**
   - This gives you slots, backup, and autoscale – all common in exam scenarios. citeturn1search5turn1search19

7. **Know where costs come from**
   - You’re billed for the **plan’s compute**, not per app (except Free). Extra apps in the same plan are “almost free” from a compute perspective. citeturn1search1turn1search27

If you can answer questions like “Which tier do I need for feature X?” and “Should I reuse or create a new plan?”, you’re in good shape for this objective.

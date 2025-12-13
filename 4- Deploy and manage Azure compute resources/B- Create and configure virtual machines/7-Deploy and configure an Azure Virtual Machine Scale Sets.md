# Deploy and Configure an Azure Virtual Machine Scale Set (VMSS)

## A. What Is a Virtual Machine Scale Set?

A **Virtual Machine Scale Set (VMSS)** is a way to deploy and manage a **group of identical VMs** as a single resource:

- All VMs (instances) use the same image and configuration.
- You can **scale out** (add instances) and **scale in** (remove instances) automatically or manually.
- Integrated with **load balancing** and **autoscale rules**.

VMSS is ideal for:

- Web front‑ends.
- API services.
- Microservices and stateless application tiers.
- Batch processing and compute farms.

For AZ‑104, you must know:

- What VMSS is and why it’s used.
- How to deploy a scale set (portal & CLI, conceptually).
- How to configure scaling, zones, and health.
- Differences between orchestration modes.

---

## B. Orchestration Modes: Uniform vs Flexible

### 1. Uniform orchestration

- Original mode for most scale sets.
- All VMs are identical, based on a **single VM model** (same size, image, configuration).
- Ideal for stateless workloads where instances are interchangeable.

### 2. Flexible orchestration

- Newer mode designed to combine the advantages of scale sets and availability sets.
- Supports **mixed VM sizes**, multiple availability zones, and advanced control.
- Integrates well with **Azure Load Balancer** or **Application Gateway** for multi‑tier, HA designs.

Exam view:

- For most basic exam scenarios, think of a scale set as a group of **identical VMs** with autoscaling and load balancing (Uniform).
- Be aware that **Flexible** mode exists and is recommended for new designs that need more control and zonal spreading.

---

## C. VMSS Architecture Overview

Typical architecture:

```text
Internet
   |
[Public IP / DNS]
   |
[Load Balancer or Application Gateway]
   |
+---------------------------+
|  Virtual Machine Scale Set|
|  Instances:               |
|   - vmss-web_0            |
|   - vmss-web_1            |
|   - vmss-web_2            |
+---------------------------+
         |
      VNet / Subnet
```

Components:

- **Scale set resource** – Template for VM instances (size, image, admin credentials, disks, network config).
- **VM instances** – Individual VMs managed by the scale set.
- **Load balancer** – Distributes traffic across instances.
- **Autoscale rules** – Automatically adjust instance count based on metrics or schedule.
- **Zones/FDs** – Instances can be spread across availability zones or fault domains for resiliency.

---

## D. Deploying a VM Scale Set in the Portal

### 1. Start creation

1. In the Azure portal, search for **“Virtual machine scale sets”**.
2. Click **Create** → **Virtual machine scale set**.

### 2. Basics tab

Key fields:

- **Subscription & Resource group**
- **Scale set name**
- **Region**
- **Orchestration mode** (Uniform or Flexible)
- **Image**
  - Marketplace image or custom image from Azure Compute Gallery.
- **Instance size**
  - VM size (for example `Standard_D2s_v5`).
- **Authentication**
  - Linux: SSH public key / password.
  - Windows: username + password.
- **Initial instance count**
  - For example 2 or 3 instances.

### 3. Disks tab

- Choose OS disk type (Standard/Premium).
- Optional data disks (applied to each instance).
- Encryption options (SSE/CMK/ADE if supported).

### 4. Networking tab

- Select or create **Virtual network** and **subnet**.
- Choose whether to create a **load balancer** or **Application Gateway**:
  - Basic/Standard Load Balancer for L4 traffic.
  - Application Gateway for HTTP/HTTPS with WAF.
- Configure **Inbound NAT pools** if you need direct SSH/RDP to instances.

### 5. Scaling tab

- **Scaling mode**
  - **Manual** – You set instance count manually.
  - **Custom autoscale** – Use rules based on metrics.
- Configure **min**, **max**, and **default** instance count.
- Create **autoscale rules**, like:
  - Scale out when avg CPU > 70% for 10 minutes (add 1–2 instances).
  - Scale in when avg CPU < 30% for 10 minutes (remove 1 instance).

### 6. Management / Monitoring / Advanced / Tags

- Enable diagnostics, boot logs, and monitoring.
- Configure identity (system‑assigned/user‑assigned managed identity).
- Add VM extensions (Custom Script, Azure Monitor agent, etc.).
- Add tags for cost and ownership.

Finally, click **Review + create** and then **Create**.

---

## E. Deploying a VM Scale Set with Azure CLI

### Example: Simple Linux Web Scale Set

```bash
# Create resource group
az group create \
  --name rg-az104-vmss \
  --location westeurope

# Create a scale set with 2 instances and a load balancer
az vmss create \
  --resource-group rg-az104-vmss \
  --name vmss-web \
  --image Ubuntu2204 \
  --upgrade-policy-mode automatic \
  --instance-count 2 \
  --vm-sku Standard_B2s \
  --admin-username azureuser \
  --generate-ssh-keys \
  --load-balancer '' \
  --public-ip-address "" \
  --vnet-name vnet-vmss \
  --subnet vmss-subnet
```

Notes:

- `--upgrade-policy-mode` can be **automatic**, **rolling**, or **manual**.
- You can integrate with a **load balancer** or configure one separately.
- You can later modify scaling rules using `az monitor autoscale` commands.

### Adding an autoscale rule (CLI high level)

```bash
# Create autoscale setting for the scale set
az monitor autoscale create \
  --resource-group rg-az104-vmss \
  --resource vmss-web \
  --resource-type Microsoft.Compute/virtualMachineScaleSets \
  --name vmss-web-autoscale \
  --min-count 2 \
  --max-count 10 \
  --count 2

# Scale out rule: CPU > 70%
az monitor autoscale rule create \
  --resource-group rg-az104-vmss \
  --autoscale-name vmss-web-autoscale \
  --condition "Percentage CPU > 70 avg 10m" \
  --scale out 1

# Scale in rule: CPU < 30%
az monitor autoscale rule create \
  --resource-group rg-az104-vmss \
  --autoscale-name vmss-web-autoscale \
  --condition "Percentage CPU < 30 avg 10m" \
  --scale in 1
```

You don’t need to memorize CLI syntax for the exam, but understanding that **autoscale uses Azure Monitor metrics and rules** is important.

---

## F. Scaling Options in VMSS

### 1. Manual scaling

- You manually set the number of instances.
- In portal: Scale set → **Scaling** → change instance count.
- CLI example:

```bash
az vmss scale \
  --resource-group rg-az104-vmss \
  --name vmss-web \
  --new-capacity 5
```

### 2. Metric-based autoscale

Use **Azure Monitor autoscale** rules based on metrics such as:

- CPU percentage
- Memory (with custom metrics or agent)
- HTTP queue length (for certain services)
- Custom application metrics

Rules define:

- Condition (for example CPU > 70% for 10 minutes).
- Action (scale out/in by N instances or percentage).
- Cooldown periods.

### 3. Schedule-based scaling

- Scale set can be configured with **scheduled autoscale** rules.
- Example: increase capacity during business hours, reduce at night.

### 4. Predictive autoscale

- Uses historical usage patterns to **predict** future demand and scale before load arrives (where available).
- Good for workloads with regular cycles (workdays vs nights/weekends).

Exam tip: Questions about **automatic scaling based on CPU** or **scheduled scaling** are almost always pointing at **Azure Monitor autoscale on a VM scale set**.

---

## G. Availability and Zones in Scale Sets

Scale sets can take advantage of **availability zones** and **fault domains**:

1. **Zonal scale set**
   - All instances are in a single zone (for example Zone 1).
   - Good for workloads heavily tied to zonal resources.

2. **Zone‑redundant scale set**
   - Instances automatically distributed across multiple zones in the region.
   - Provides resilience to zonal failures.

3. **Fault domains** (regions without zones)
   - In non‑zonal regions, scale sets distribute instances across multiple fault domains (similar to availability sets).

When creating a VMSS in the portal:

- On the **Basics** or **Scaling**/**Availability** settings page, you can choose:
  - **No infrastructure redundancy**.
  - **Availability zone** (one or more zones).
- For multi‑zone distribution, choose multiple zones (for example 1, 2, 3).

Example CLI snippet:

```bash
az vmss create \
  --resource-group rg-az104-vmss \
  --name vmss-web-zones \
  --image Ubuntu2204 \
  --zones 1 2 \
  --instance-count 2 \
  --vm-sku Standard_D2s_v5 \
  --admin-username azureuser \
  --generate-ssh-keys
```

Exam tip: If the requirement says “web tier must remain available when a whole zone fails and scale automatically based on CPU usage” → the correct design is **VM scale set distributed across zones + autoscale rules + load balancer**.

---

## H. Updating and Managing Instances

### 1. Model and instances

A scale set has a **model** and **instances**:

- **Model** – Template with properties such as image, size, extensions, and configuration.
- **Instances** – Actual VMs created from the model.

When you change the **model** (for example, update image or extensions), you may need to **apply upgrades** to instances.

### 2. Upgrade policies

- **Automatic** – Instances are upgraded automatically when the model changes.
- **Rolling** – Instances are upgraded in batches to reduce impact.
- **Manual** – You trigger upgrades explicitly.

### 3. Common management tasks

- **Increase/decrease capacity** – Change instance count via portal/CLI/PowerShell.
- **Reimage instance** – Reset VM to original image (useful for drift from baseline).
- **Delete instance** – Remove an individual instance if unhealthy.
- **Protect from scale‑in** – Mark an instance so autoscale doesn’t remove it (for troubleshooting or special roles).

Example CLI (protect from scale‑in, conceptually):

```bash
az vmss update-instances \
  --resource-group rg-az104-vmss \
  --name vmss-web \
  --instance-ids 2 \
  --set protectFromScaleIn=true
```

You don’t need the exact command for the exam, but you should know that individual instances can be marked to **avoid scale‑in**.

---

## I. VMSS vs Single VM + Availability Set

Comparison summary:

| Feature | Single VM | Availability Set | VM Scale Set |
|--------|-----------|------------------|-------------|
| # of instances | 1 (manually add more) | Multiple (manually managed) | Many, centrally managed |
| Autoscale | No (manual) | No (manual) | Yes (metric/schedule/predictive) |
| Load balancing | Must add manually | Must add manually | Integrated in design |
| Zone‑aware | With manual deployment | Not zone‑aware by design | Zone‑aware (zonal/zone‑redundant) |
| Best for | Fixed small workloads | Traditional HA apps | Cloud‑native elastic workloads |

Exam tip: If the scenario uses phrases like *“automatically scale out based on CPU usage”* or *“handle unpredictable traffic spikes”* → choose **Virtual Machine Scale Sets**, not single VMs or plain availability sets.

---

## J. Best Practices

1. **Design stateless application instances**
   - Store state in external services (databases, caches, storage).
   - Makes scale out/in safe and easy.

2. **Use health probes and load balancing**
   - Ensure the load balancer removes unhealthy instances.
   - Combine with Application Gateway or Front Door for web workloads.

3. **Plan autoscale wisely**
   - Set conservative min and max instance counts.
   - Use appropriate cool‑down to avoid “flapping” (constant scale in/out).

4. **Use managed identities and extensions**
   - Configure managed identity for secure access to Key Vault, Storage, etc.
   - Use VM extensions for configuration management (Custom Script Extension, DSC, cloud‑init, etc.).

5. **Combine zones and scale sets**
   - For high availability, use **multi‑zone scale sets** and geo‑replicated data services.

6. **Monitoring and logging**
   - Send metrics and logs to Azure Monitor/Log Analytics.
   - Create alerts on CPU, instance count, failures, or error rates.

---

## K. Quick Exam Summary

- **VMSS** = group of VMs managed as a single resource with **autoscale** and **load balancing**.
- Orchestration modes: **Uniform** (identical instances) and **Flexible** (more advanced, mixed sizes, zonal, etc.).
- You can configure **manual**, **metric‑based**, **scheduled**, and **predictive** autoscale.
- Scale sets can span **availability zones** and fault domains for high availability.
- Use VM scale sets when a requirement mentions **automatic scaling**, **elastic web tiers**, or **handling spikes in demand**.
- Always design scale set workloads to be **stateless** or store state externally.

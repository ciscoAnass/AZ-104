# Deploy Virtual Machines to Availability Zones and Availability Sets

## A. Why Availability Matters

Azure regions can experience:

- Hardware failures (rack, host, storage).
- Planned maintenance events.
- Datacenter‑level issues (cooling, power, network, flood, etc.).

Availability features help you **design for resiliency**. For the AZ‑104 exam, you must understand:

- **Availability sets** (within a single datacenter).
- **Availability zones** (across multiple datacenters).
- How to deploy VMs into them.
- How they affect SLAs and fault tolerance.

---

## B. Key Concepts: Fault Domains and Update Domains

### Fault domain (FD)

- Group of physical hardware (hosts, racks) that share a common power source and network switch.
- A failure in one fault domain should not affect other domains.

### Update domain (UD)

- Group of VMs that are updated/rebooted together during planned maintenance.
- Azure staggers maintenance across update domains to keep overall app available.

In an **availability set**:

- VMs are spread across **multiple fault domains** and **update domains** for redundancy.
- Typical default: 2–3 fault domains, 5 update domains (configurable).

---

## C. Availability Sets

### 1. What is an Availability Set?

- A **logical grouping** of VMs in a single Azure region and datacenter.
- Ensures that VMs are distributed across multiple fault and update domains.
- Protects against host or rack failure and coordinated maintenance reboots.

**Requirements:**

- You must create an availability set **before** creating the VMs (or when creating the first VM).
- You **cannot** move an existing VM into an availability set after creation. You would need to recreate the VM.

### 2. How it works

If you create multiple VMs in an availability set:

- Azure automatically places VMs in different fault domains.
- For maintenance, Azure updates one update domain at a time, so not all VMs reboot simultaneously.

Example:

```text
Availability Set "AS-WebApp"
  Fault Domains: FD0, FD1, FD2
  Update Domains: UD0..UD4

  VM1 → FD0 / UD0
  VM2 → FD1 / UD1
  VM3 → FD2 / UD2
```

If FD1 fails, only VM2 is affected; VMs in FD0/FD2 continue to run.

### 3. SLA impact

- Two or more VMs in an availability set achieve a higher **SLA** (for example 99.95% uptime) than a single VM.
- One VM alone in an availability set doesn’t improve SLA; you need at least two.

### 4. When to use Availability Sets

- When your application can run in **a single datacenter**, but you need protection from host/rack failures and planned maintenance.
- Legacy or existing design where **availability zones** are not used or not available.

Exam tip: If the scenario says “must protect against rack failures but can be in single datacenter” and **zones are not mentioned**, an **availability set** with 2+ VMs and a load balancer is a valid answer.

---

## D. Availability Zones

### 1. What is an Availability Zone?

- Physically separate datacenters within an Azure region.
- Each zone has independent power, cooling, and networking.
- Zones are labeled as **Zone 1**, **Zone 2**, **Zone 3**, etc., within a region.

With availability zones:

- You deploy VMs **into specific zones**.
- An issue impacting one datacenter is unlikely to affect others.
- SLA for multi‑zone deployments is typically higher (for example 99.99% for 2+ VMs across zones).

### 2. Zonal vs zone‑redundant resources

- **Zonal resource** – Tied to a single zone (for example a VM or a zonal disk deployed in Zone 1).
- **Zone‑redundant resource** – Spread across multiple zones (for example zone‑redundant storage, zone‑redundant load balancer).

### 3. When to use Availability Zones

- For **mission‑critical workloads** needing protection from datacenter‑level failures.
- When latency between zones is acceptable for your application (typically low for in‑region traffic).
- When you want highest availability SLA within a region.

Exam tip: If the requirement is “must remain available when one datacenter in the region fails” → you need **availability zones** (plus load balancing across VMs in different zones).

---

## E. Availability Options at VM Creation

When you create a VM in the portal (Basics tab), you choose **Availability options**:

1. **No infrastructure redundancy required**
   - Single VM without availability set or zones.
   - Lower SLA.

2. **Availability zone**
   - Choose Zone 1, 2, or 3.
   - VM is pinned to that zone.

3. **Availability set**
   - Choose an existing availability set or create a new one.
   - VMs in the set are spread across FDs/UDs.

You cannot:

- Change a VM from non‑zonal to zonal after creation.
- Move an existing VM into an availability set; you must recreate VM (for example from image or disk).

---

## F. Deploying VMs to Availability Sets

### 1. Portal

1. Create an **availability set**:
   - In the portal, search for **Availability sets**.
   - Create a new one:
     - Choose subscription and resource group.
     - Select region (same region where VMs will be deployed).
     - Configure fault domains (for example 2) and update domains (for example 5).

2. Create VMs in that availability set:
   - When creating a VM, in **Availability options**, select **Availability set**.
   - Pick the previously created availability set.
   - Repeat for each VM that should be in the set.

3. Add load balancing:
   - Use an **Azure Load Balancer** or **Application Gateway** to distribute traffic across VMs in the availability set.

### 2. Azure CLI example

```bash
# Create availability set
az vm availability-set create \
  --name as-webapp \
  --resource-group rg-az104-compute \
  --platform-fault-domain-count 2 \
  --platform-update-domain-count 5 \
  --location westeurope

# Create VM in availability set
az vm create \
  --resource-group rg-az104-compute \
  --name vm-web-01 \
  --image Ubuntu2204 \
  --availability-set as-webapp \
  --size Standard_B2s \
  --admin-username azureuser \
  --generate-ssh-keys
```

Repeat for `vm-web-02`, `vm-web-03`, etc., with the same `--availability-set` parameter.

---

## G. Deploying VMs to Availability Zones

### 1. Portal

When creating the VM:

1. On **Basics** tab, set **Availability options** to **Availability zone**.
2. Choose **Zone 1**, **Zone 2**, or **Zone 3**.
3. Create at least **two VMs in different zones** for high availability.

Example architecture:

```text
Region: West Europe

Zone 1:
  - vm-web-01
Zone 2:
  - vm-web-02

Front-end:
  - Zone-redundant Load Balancer or Application Gateway
```

### 2. Azure CLI example

```bash
# VM in zone 1
az vm create \
  --resource-group rg-az104-compute \
  --name vm-web-z1 \
  --image Ubuntu2204 \
  --size Standard_D2s_v5 \
  --zone 1 \
  --admin-username azureuser \
  --generate-ssh-keys

# VM in zone 2
az vm create \
  --resource-group rg-az104-compute \
  --name vm-web-z2 \
  --image Ubuntu2204 \
  --size Standard_D2s_v5 \
  --zone 2 \
  --admin-username azureuser \
  --generate-ssh-keys
```

Then create a **zone‑redundant Load Balancer** or Application Gateway in front of these VMs.

---

## H. Availability Sets vs Availability Zones (Comparison)

| Feature | Availability Set | Availability Zone |
|--------|------------------|-------------------|
| Scope | Single datacenter (within region) | Multiple datacenters (within region) |
| Protection from | Host/rack failure, maintenance | Datacenter‑level failures + host failures |
| SLA (2+ VMs) | Higher than single VM (for example 99.95%) | Highest standard SLA (for example 99.99%) |
| Configuration time | Choose availability set at VM creation | Choose zone at VM creation |
| Move existing VMs | Cannot move into set directly; must recreate | Cannot change zone; must recreate VM |
| Network latency | Very low, same datacenter | Slightly higher between zones but still low (in‑region) |

Exam tip: If the requirement explicitly calls out *“tolerate zonal failure”*, *“multiple datacenters”*, or *“highest SLA in region”* → pick **availability zones**. If it only mentions host/rack failures and is older design, **availability sets** are acceptable.

---

## I. Integration with Other Services

1. **Load balancing**
   - Use **Azure Load Balancer** for TCP/UDP traffic across VMs in availability sets or zones.
   - Use **Application Gateway** or **Azure Front Door** for HTTP/HTTPS load balancing and web application firewall (WAF).

2. **Disks**
   - Zonal VMs use disks that are also zonal.
   - Zone‑redundant disks exist for some SKUs (spread across zones).

3. **Scale sets**
   - Virtual Machine Scale Sets can be:
     - Spread across multiple **availability zones**.
     - Configured with multiple fault domains when zones are not used.

---

## J. Best Practices

1. **Use zones for critical workloads**
   - If region supports zones and your workload is mission‑critical, deploy across zones.

2. **Use at least two VMs**
   - Availability features only help when you have **multiple instances**.

3. **Combine with load balancing and health probes**
   - Ensure traffic is automatically redirected away from unhealthy instances.

4. **Plan for data tier as well**
   - Use zone‑redundant or geo‑redundant options for databases and storage.

5. **Monitor and test failover**
   - Regularly test your failover behavior and monitor SLAs.

---

## K. Quick Exam Summary

- **Availability sets** spread VMs across **fault domains** and **update domains** in a single datacenter.
- **Availability zones** spread VMs across **physically separate datacenters** within a region.
- You must choose **availability options during VM creation**; you can’t “flip a switch” later to put the same VM into a zone or availability set.
- Higher SLAs are achieved when you deploy **multiple VMs** across sets/zones and use load balancing.
- For the highest resilience within a region → **availability zones** are the preferred option.

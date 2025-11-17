# Manage Virtual Machine Sizes

## A. What Is a VM Size?

A **VM size** defines the hardware resources allocated to your Azure virtual machine:

- Number of virtual CPUs (vCPUs)
- Amount of RAM
- Max number of data disks
- Max IOPS and throughput for disks
- Network bandwidth
- Support for Premium/Ultra disks, GPUs, etc.

Choosing the right size is critical for performance, cost, and availability. For AZ‑104 you must understand:

- VM size **families/series** and what they’re used for.
- How to **select** a size.
- How to **resize** a VM (portal, CLI, PowerShell) and limitations.

---

## B. VM Size Families (Series)

Azure organizes VM sizes into **families** (series). Common ones:

| Category | Examples | Typical Use |
|----------|----------|------------|
| **General purpose** | D‑series, B‑series, A‑series | Balanced CPU/RAM. Web servers, small DBs, app servers. |
| **Compute optimized** | F‑series | High CPU‑to‑memory ratio. Batch processing, app servers. |
| **Memory optimized** | E‑series, M‑series | In‑memory DBs, large caches, analytics. |
| **Storage optimized** | L‑series | High disk throughput and IOPS. Big data, NoSQL DBs. |
| **GPU** | NC, ND, NV series | Graphics, AI/ML, rendering, visualization. |
| **High performance compute (HPC)** | H‑series | Compute‑intensive workloads, simulations. |

Examples:

- **B‑series** – Burstable VMs. They accumulate credits when under‑utilized and can “burst” CPU usage when needed. Great for low/medium usage workloads (dev, small web apps).
- **D‑series** – General‑purpose VMs for most production workloads.
- **E‑series/M‑series** – Memory‑intensive workloads like large databases or SAP applications.

Exam tip: When a scenario mentions “CPU‑intensive but not much memory” → **Compute optimized (F‑series)** is usually correct. If it mentions “very large in‑memory database” → **Memory optimized (E/M series)**.

---

## C. VM Size Names and Suffixes

VM size names encode information:

Example: `Standard_D4s_v5`

- `Standard` – Pricing tier (Vs Basic). Basic is mostly legacy; focus on Standard.
- `D` – Series (general purpose).
- `4` – vCPU count (approximate, i.e., 4 vCPUs).
- `s` – Supports Premium SSDs (storage optimized for Premium).
- `v5` – Generation/version.

Common suffixes:

- **s** – Supports Premium SSDs.
- **ds** – Often indicates Premium‑capable versions in older naming.
- **vX** – Version (newer hardware generation).

You don’t need to memorize every pattern, but you should recognize that **“s” → Premium SSD capable**, and newer versions (v4, v5) usually offer better performance.

---

## D. Factors When Choosing a Size

1. **Workload characteristics**
   - CPU intensive? Choose compute‑optimized.
   - Memory intensive? Choose memory‑optimized.
   - Disk I/O intensive? Choose storage‑optimized or Premium/Ultra disk support.
   - Requires GPU? Choose GPU‑enabled family.

2. **Performance limits**
   - IOPS/throughput per disk **and** per VM size.
   - Max NICs and network bandwidth.

3. **Cost**
   - Larger VMs cost more per hour.
   - Burstable VMs (B‑series) can cut cost for spiky workloads.

4. **Region availability**
   - Not all sizes are available in every region.
   - Some sizes are restricted or quota‑limited.

5. **Supported features**
   - Premium SSD, Ultra disk, encryption at host, ephemeral OS disks, etc.

Exam tip: Many questions present a table of requirements (vCPU, RAM, IOPS) and ask which VM size/family is most appropriate. You won’t need exact numeric limits, but you must pick **the right category**.

---

## E. Viewing and Selecting Sizes

### 1. Portal

When creating or resizing a VM:

- On the **Size** blade, you see:
  - vCPUs, RAM, temp storage
  - Premium/Ultra support
  - Price (estimated, per region)
- You can filter by:
  - Family (general purpose, compute optimized, etc.)
  - vCPU count
  - RAM

### 2. Azure CLI

List sizes available in a region:

```bash
az vm list-sizes --location westeurope -o table
```

Check available resize options for a specific VM:

```bash
az vm list-vm-resize-options \
  --resource-group rg-az104-compute \
  --name vm-app01 \
  -o table
```

### 3. PowerShell

```powershell
Get-AzVMSize -Location "westeurope"

# Resize options for specific VM
Get-AzVM -Name "vm-app01" -ResourceGroupName "rg-az104-compute" |
    Get-AzVMSize
```

---

## F. Resizing a VM (Change VM Size)

### 1. Portal

Steps to change size:

1. Open the VM in the portal.
2. In the left menu, under **Settings** or **Availability + scale**, select **Size**.
3. View available sizes for that VM.
4. Choose new size and click **Resize**.

Important notes:

- If the VM is running, resizing typically **restarts** it (brief downtime).
- If the desired size is not shown:
  - Stop (deallocate) the VM and re‑open the Size blade; more sizes may appear.
  - If still unavailable, that size might not be available on the current hardware cluster or in that region.

### 2. Azure CLI

```bash
# Show current size
az vm show \
  --resource-group rg-az104-compute \
  --name vm-app01 \
  --query "hardwareProfile.vmSize" \
  -o tsv

# Resize
az vm resize \
  --resource-group rg-az104-compute \
  --name vm-app01 \
  --size Standard_D4s_v5
```

The VM will restart as part of the resize. If needed, you can stop (deallocate) first:

```bash
az vm deallocate -g rg-az104-compute -n vm-app01
az vm resize -g rg-az104-compute -n vm-app01 --size Standard_D4s_v5
az vm start -g rg-az104-compute -n vm-app01
```

### 3. PowerShell

```powershell
$vm = Get-AzVM -Name "vm-app01" -ResourceGroupName "rg-az104-compute"
$vm.HardwareProfile.VmSize = "Standard_D4s_v5"
Update-AzVM -VM $vm -ResourceGroupName "rg-az104-compute"
```

Exam tip: Resizing a VM in an **availability set** may require stopping **all VMs** in the set before changing sizes, if the new size is not available on the current hardware cluster.

---

## G. Size, Disks, and Performance

VM size and disk performance are connected:

- Each VM size has:
  - Max total IOPS
  - Max throughput (MB/s)
  - Max number of data disks
- Each disk type (Standard HDD, Standard SSD, Premium SSD, Premium SSD v2, Ultra) has its own limits.

To achieve a performance target:

1. Choose a VM size that supports your IOPS/throughput requirements.
2. Choose appropriate disk types and sizes.
3. Combine multiple data disks with **striping** (Storage Spaces / RAID) for higher performance if needed.

Example pattern (exam style):

> You must support a high‑transaction database with low latency and high throughput. What should you choose?

Likely answer:

- Memory‑optimized VM (for example E‑series).
- Premium or Ultra disks.
- Possibly multiple data disks striped together.

---

## H. Availability and Resizing Considerations

1. **Availability sets**
   - All VMs in the set must usually have the same or compatible sizes.
   - Resizing may require stopping all VMs in the set.

2. **Availability zones**
   - Size must be available in that zone.
   - Not all sizes are offered in every zone.

3. **Quota and limits**
   - Each subscription has default vCPU quotas per region.
   - If you cannot create a larger VM, you might need a **quota increase** request.

4. **Spot VMs**
   - Spot VMs use the same sizes as regular VMs but are subject to eviction when Azure needs capacity.
   - Choose size based on workload + budget.

Exam tip: If a scenario says “VM cannot be resized to the required size in this region,” look for answers that suggest **deallocating** the VM first or **moving to a different region** where the size is available (or **Requesting a quota increase** if the problem is vCPU quota).

---

## I. Best Practices

1. **Right‑size continuously**
   - Use Azure Monitor metrics to see CPU/memory usage.
   - Downsize under‑utilized VMs to save cost.
   - Upsize overloaded VMs to improve performance.

2. **Standardize sizes**
   - Use a small set of approved sizes for easier management.
   - Use Azure Policy to restrict allowed VM sizes.

3. **Use dev/test offers**
   - For non‑production, use Azure Dev/Test subscriptions and B‑series where possible.

4. **Plan ahead for scaling**
   - If you expect growth, choose a size family that offers larger SKUs in the same series (for easier scaling).

5. **Combine with scale sets or PaaS**
   - For elastic workloads, consider **Virtual Machine Scale Sets** or PaaS services instead of manually resizing single VMs.

---

## J. Quick Exam Summary

- VM sizes define compute, memory, disk, and network limits.
- Families/series are aligned with workload types:
  - General purpose (D/B), compute optimized (F), memory optimized (E/M), storage optimized (L), GPU (NC/ND/NV), HPC (H).
- Suffix `s` often means **Premium storage capable**.
- You can resize VMs via **portal**, **CLI**, or **PowerShell**.
- Some sizes require the VM to be **stopped (deallocated)** before changing.
- Consider **region availability**, **quotas**, and **availability sets/zones** when resizing or choosing sizes.

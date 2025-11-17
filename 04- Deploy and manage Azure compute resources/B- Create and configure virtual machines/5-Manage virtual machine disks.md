# Manage Virtual Machine Disks

## A. Disk Types and Roles in a VM

Azure VMs use several kinds of disks. For AZ‑104 you must clearly distinguish them.

### 1. OS disk

- Contains the operating system.
- Is a **managed disk** by default.
- Persisted in Azure Storage (unless using ephemeral OS disks).
- Typically 127 GiB or more; can be resized.
- Can be backed up, snapshotted, and encrypted.

### 2. Data disks

- Additional managed disks attached to the VM.
- Used for application data, databases, logs, etc.
- You can attach multiple data disks (limit depends on VM size).
- Each has its own size, type (Standard/Premium/Ultra), and performance limits.

### 3. Temporary disk

- Local disk presented as `D:` on Windows or `/dev/sdb` on Linux (path can vary).
- Stored on the **physical host** (not on managed disk storage).
- Data is **lost** if the VM is deallocated or moved to another host.
- Useful for temporary data, pagefile/swap, caches.
- **Never** store important data here.

### 4. Ephemeral OS disk

- OS disk stored on host local storage (like temp disk).
- Very fast, **non‑persistent**.
- Ideal for stateless workloads, scale set instances, short‑lived VMs.
- Not compatible with Azure Backup, Azure Site Recovery, or Azure Disk Encryption.

Exam tip: If a question says “VM must reboot quickly and does not need to preserve OS changes” → answer likely involves **ephemeral OS disk**.

---

## B. Azure Managed Disk Types

Azure managed disks currently include these types:

| Disk Type | Performance | Typical Use |
|----------|-------------|-------------|
| **Ultra Disk** | Highest IOPS/throughput, configurable | Top‑tier databases, SAP HANA, critical low‑latency workloads. |
| **Premium SSD v2** | High performance, configurable IOPS/throughput | Production databases, transaction‑heavy apps. |
| **Premium SSD** | High performance SSD | Production workloads needing consistent low latency. |
| **Standard SSD** | Balanced cost/performance | Web servers, lightly used workloads. |
| **Standard HDD** | Lowest cost, spinning disks | Dev/test, backup, cold data. |

Key ideas:

- **Premium SSD/Ultra** require VM sizes that support Premium/Ultra disks.
- You pay for disk **capacity** and, for some types, provisioned performance.
- You can **convert** between most disk types, often online (Premium ↔ Standard SSD ↔ Standard HDD). Ultra has special rules.

Exam tip: If the workload is a production SQL database needing low latency → choose **Premium SSD** or **Premium SSD v2/Ultra** with appropriate VM size. If it’s dev/test with low performance needs → **Standard HDD/SSD**.

---

## C. Creating and Attaching Data Disks

### 1. Attaching a new data disk in the portal

Steps:

1. Open the VM in the portal.
2. Go to **Disks** blade.
3. Click **Add data disk**.
4. For **Name**, choose **Create disk** (or attach existing).
5. Set:
   - Disk type (Standard/Premium/Ultra).
   - Size (GiB).
   - Encryption options.
6. Save. Azure attaches the disk to the VM (typically as `LUN 0`, `LUN 1`, etc.).
7. Inside the VM OS:
   - Initialize the disk (Disk Management in Windows, `fdisk`/`lsblk` in Linux).
   - Create partitions and file systems.
   - Mount and configure path/drive letters.

### 2. Azure CLI example

```bash
# Create a managed disk
az disk create \
  --resource-group rg-az104-compute \
  --name disk-data01 \
  --size-gb 256 \
  --sku Premium_LRS

# Attach to VM
az vm disk attach \
  --resource-group rg-az104-compute \
  --vm-name vm-app01 \
  --name disk-data01
```

### 3. Detaching and deleting disks

- To **detach**, go to VM → Disks → remove the data disk entry, or use CLI:

```bash
az vm disk detach \
  --resource-group rg-az104-compute \
  --vm-name vm-app01 \
  --name disk-data01
```

- Detaching **does not delete** the managed disk resource; it remains in the resource group and can be re‑attached.
- To completely remove it, delete the disk resource separately.

Exam tip: If the question says “must keep the data but temporarily detach the disk from the VM,” you should **detach** the disk and do **not** delete the disk resource.

---

## D. Resizing and Changing Disk Types

### 1. Resizing a disk

You can increase (but not decrease) the size of a managed disk.

Portal steps:

1. Open the **disk resource** (not the VM).
2. In **Settings → Size + performance**, increase the size (GiB).
3. Save changes.
4. Inside the VM OS, extend the partition and file system to use the additional space.

CLI example:

```bash
az disk update \
  --resource-group rg-az104-compute \
  --name disk-data01 \
  --size-gb 512
```

Notes:

- Increasing disk size may increase performance (more IOPS/throughput tiers).
- To resize OS disks, you may need to **deallocate** the VM first in some scenarios.

### 2. Converting disk type

You can convert between Standard HDD, Standard SSD, and Premium SSD:

```bash
az disk update \
  --resource-group rg-az104-compute \
  --name disk-data01 \
  --sku Premium_LRS
```

Converting to/from **Ultra** sometimes requires extra steps (creating a new Ultra disk from a snapshot, then swapping).

Exam hint: A common pattern is upgrading a disk from Standard to Premium to reduce latency and improve IOPS without changing the VM size (assuming the VM supports Premium).

---

## E. Snapshots and Images

### 1. Snapshots

- A **snapshot** is a read‑only crash‑consistent backup of a single disk at a point in time.
- You can create snapshots manually or via automation.

Use cases:

- Quick backup before making a risky change.
- Source for creating new disks in the same or another region.

CLI example:

```bash
# Create snapshot
az snapshot create \
  --resource-group rg-az104-compute \
  --name snap-data01 \
  --source disk-data01

# Create a disk from the snapshot
az disk create \
  --resource-group rg-az104-compute \
  --name disk-from-snap \
  --source snap-data01
```

### 2. Managed images (VM‑level)

- A **managed image** can be captured from a VM to create new VMs.
- It contains the OS disk and optionally data disks.
- More modern pattern: **Azure Compute Gallery** images and image versions for better scaling and regional replication.

Exam tip: For single‑disk protection use **snapshots**; for templating VMs with pre‑installed apps use **images** (often in Azure Compute Gallery). For full backup with scheduling and retention use **Azure Backup**.

---

## F. Disk Performance and VM Limits

Disk performance depends on:

1. **Disk SKU and size**
   - Larger disks usually support more IOPS and throughput.
   - Premium SSD/Ultra can reach very high IOPS.

2. **VM size**
   - Each VM size has a max aggregate IOPS and throughput across all attached disks.
   - If you hit the VM limit, adding more disks may not increase performance.

3. **Striping disks**
   - You can stripe multiple data disks using Storage Spaces (Windows) or LVM/mdadm (Linux) to combine performance.

Simple example (Windows):

- Attach 4 Premium disks.
- Combine them into a Storage Spaces virtual disk with striping.
- Use this volume for data files of a database.

Exam hint: If you need more disk performance than a single disk can deliver, but the VM has available IOPS budget → use **multiple data disks in a stripe set**.

---

## G. Disk Encryption and Backup (High Level)

### 1. Encryption

- **Storage Service Encryption (SSE)** is enabled by default on managed disks.
- You can use **customer‑managed keys (CMK)** in Key Vault for managed disks.
- **Azure Disk Encryption (ADE)** encrypts from inside the OS using BitLocker/dm‑crypt.
- **Ephemeral OS disks** are **not** supported with ADE or Backup.

### 2. Backup

- Use **Azure Backup** to protect VM disks at the VM level.
- Backup captures the OS disk and all data disks.
- Restoring a VM from backup re‑creates the VM (or you can restore individual disks).

Exam tip: If a requirement says “must support item‑level backup and easy restore for the entire VM and all disks on a schedule,” the correct answer is usually **Azure Backup**, not snapshots.

---

## H. Shared Disks (Advanced Concept)

Azure supports **shared disks** on some disk types (typically Standard SSD / Premium in specific modes):

- A managed disk can be attached in **read/write** mode to multiple VMs (for example, for clustered workloads).
- Requires specific OS/cluster configuration (Windows Failover Cluster, etc.).

For AZ‑104, you just need to recognize:

- Shared disks exist for building **clustered solutions**.
- There are limitations on the number of VMs and scenarios.
- Most standard workloads do **not** require shared disks.

---

## I. Best Practices

1. **Use managed disks** (default)
   - Simpler management, built‑in availability, easy snapshots.
   - Avoid legacy unmanaged disks.

2. **Choose disk type based on workload**
   - Dev/test: Standard HDD or Standard SSD.
   - Production transactional DB: Premium SSD / Premium SSD v2 / Ultra.
   - Logs, cold data: Standard HDD or lower‑tier disks.

3. **Separate OS and data**
   - Put application and data files on data disks, not on the OS disk.
   - Easier backup, scaling, and migration.

4. **Avoid storing important data on the temporary disk**
   - It’s not persistent; only use for cache/pagefile/swap.

5. **Monitor disk metrics**
   - Use Azure Monitor to track IOPS, throughput, latency.
   - Adjust disk type/size or VM size when reaching limits.

6. **Combine with encryption and backup**
   - Use encryption (SSE/CMK/ADE) according to compliance needs.
   - Configure Azure Backup for production workloads.

---

## J. Quick Exam Summary

- Understand **OS**, **data**, **temporary**, and **ephemeral OS** disks.
- Know the main disk types: **Standard HDD**, **Standard SSD**, **Premium SSD**, **Premium SSD v2**, and **Ultra**.
- You can **attach**, **detach**, **resize**, and **change disk type** for managed disks.
- **Snapshots** are disk‑level backups; **images** (often via Azure Compute Gallery) are for templated VM deployment.
- Disk performance depends on both **disk SKU/size** and **VM size**.
- Temporary disk is **non‑persistent**; do not store important data there.
- Ephemeral OS disks are fast but **stateless** and cannot be backed up or encrypted with ADE.

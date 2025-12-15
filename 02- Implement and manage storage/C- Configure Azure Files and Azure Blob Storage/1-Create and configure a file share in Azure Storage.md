# Create and Configure a File Share in Azure Storage

## A. Azure Files Basics

### What is Azure Files?

Azure Files provides **fully managed file shares in the cloud** that you access using:

- **SMB (Server Message Block)** – SMB 3.0/3.1.1, for Windows, Linux, macOS.
- **NFS 4.1** – for Linux/Unix workloads.
- **REST API** – programmatic access.

Think of Azure Files as **“file server as-a-service”**:

- No OS to patch.
- No disks, RAID, or clustering to manage.
- Integrated with Azure identity and networking.

### When to Use Azure Files (Exam view)

Use Azure Files when you need:

- **Lift & shift of file shares** from on‑premises file servers.
- **User profiles / FSLogix** profiles for AVD/Remote Desktop.
- **Application configuration** files shared by multiple VMs/containers.
- **Hybrid**: on‑prem servers caching Azure Files via **Azure File Sync**.

Compare quickly:

| Need | Use |
|------|-----|
| SMB/NFS file share, OS-level mount | **Azure Files** |
| Object storage (images, backups, logs) | **Blob Storage** |
| Virtual machine OS/data disks | **Azure Disks (page blobs)** |

---

## B. File Share Types and Tiers

### 1. Standard vs Premium

**Standard file shares** (in **GPv2** storage accounts):

- Backed by HDD-based storage.
- **Max capacity** up to 100 TiB (with large file share enabled).
- Supports **SMB** and **NFS** (depending on configuration).
- Supports **three access tiers** for SMB shares:  
  - **Transaction optimized** – default; balanced cost/IOPS.  
  - **Hot** – higher storage cost, lower transaction cost.  
  - **Cool** – lower storage cost, higher transaction cost (for infrequently accessed shares). citeturn0search11

**Premium file shares** (in **FileStorage** accounts):

- Backed by SSDs.
- **Provisioned** capacity model → you choose GiB, IOPS and throughput scale with size.
- Very low latency, high throughput.
- Ideal for:
  - AVD / FSLogix user profiles.
  - High‑IOPS line-of-business apps.
  - SQL / application logs that demand fast I/O.

### 2. Protocol Options

When you create a share, you decide the **protocol**:

- **SMB** share:
  - Used by Windows clients, many Linux clients.
  - Can integrate with **Active Directory / Azure AD Kerberos** for identity-based access.
- **NFS** share:
  - Linux workloads that expect NFS.
  - Different auth model (client/network based).

> Exam tip: If the question explicitly mentions **SMB 3.0 over the internet**, **port 445**, or “map a network drive” → they’re talking about **Azure Files** over SMB.

---

## C. Design Decisions Before Creating a File Share

### 1. Choose the Right Storage Account Type

- For **standard** file shares → create a **general-purpose v2 (GPv2)** account.
- For **premium** file shares → create a **FileStorage** account.
- Choose region, redundancy, and performance:
  - **Redundancy** options commonly used:
    - **LRS** – cheapest, single-region.
    - **ZRS** – zone‑redundant within region (higher availability).
    - **GZRS/RA-GZRS** – cross‑region plus zone redundancy (for DR).

> Exam pattern: If they ask about **high availability within a region** for file shares → choose **ZRS** if supported in that region.

### 2. Size & Quota (Share Capacity)

Each file share has a **quota** (max size):

- Standard shares (with large file share enabled) → up to **100 TiB**.
- Premium shares → capacity is **provisioned**; throughput/IOPS scale with size.

You can change the quota later (within limits), but understand:

- Larger quota = more potential throughput for premium.
- Quota is a hard limit; writes fail when quota is reached.

### 3. Networking

For secure access, you typically combine:

- **Storage firewall**:
  - Allow all networks (not recommended).
  - Allow only **selected networks** (VNets + IP ranges).
- **Private endpoints**:
  - Provide **private IP** in your VNet for the storage account.
  - Traffic stays on Microsoft backbone instead of public internet.

> Exam tip: If requirement says “**no public internet exposure**” or “traffic must stay on private IP addresses”, answer: **Private endpoints + deny public network access**.

### 4. Authentication & Authorization

Azure Files supports several authentication methods:

1. **Storage account key / Shared Key**  
   - Grants full access (like root password) – use only for admin/automation.
2. **Shared Access Signatures (SAS)**  
   - Time‑limited, permission‑limited tokens (good for delegated access).
3. **Identity-based access for SMB**:
   - **On‑prem AD DS** integration, or
   - **Azure AD Kerberos** for Azure AD-joined VMs.
   - You use **NTFS ACLs** & AD identities for fine-grained permissions.

> For the AZ‑104 exam, remember: **Use identity-based access for SMB shares** whenever possible; avoid long‑lived account keys.

---

## D. Creating a File Share (Portal, High-Level)

### 1. Create the Storage Account (if not already existing)

1. In the **Azure portal**, select **Create a resource → Storage account**.
2. Choose:
   - Subscription & Resource group.
   - Storage account name (globally unique, lowercase).
   - Region & redundancy (LRS/ZRS/GZRS).
   - Performance: **Standard** or **Premium**.
3. On **Advanced** and **Networking** tabs, configure:
   - Secure transfer required (HTTPS only).
   - Public network access (enable only if needed).
   - Private endpoints if required.
4. Review + create.

### 2. Create the File Share

From the storage account:

1. In the left menu, under **Data storage**, select **File shares**.
2. Click **+ File share**.
3. Fill settings:

   - **Name**  
     - Lowercase letters, numbers, and hyphens (`-`).  
     - 3–63 characters.  
     - Must start and end with letter or number (no leading/trailing `-`).

   - **Tier (standard SMB)**  
     - **Transaction optimized** – for most workloads.  
     - **Hot** – frequent access, more data at rest cost, lower transaction cost.  
     - **Cool** – infrequent access, less data at rest cost, higher transaction cost.

   - **Quota (GiB or TiB)**  
     - Set max share size (e.g., 1024 = 1 TiB).

   - **Protocol**  
     - SMB (default) or NFS depending on scenario.

4. Click **Create**.

> CLI note (no need to memorize exact syntax, but useful understanding):  
> `az storage share-rm create` or `az storage share create` commands can create shares from scripts.

---

## E. Connecting to the File Share

### 1. From Windows (SMB)

In the portal, open your file share and click **Connect**. Azure will generate a **PowerShell or CMD script** that:

- Uses the storage account key or Azure AD auth.
- Maps the share as a **network drive**, e.g. `Z:`.

Simplified example (account key-based):

```powershell
net use Z: \\storageaccountname.file.core.windows.net\myshare ^
    /u:Azure\storageaccountname <storage_account_key>
```

Key points for the exam:

- SMB uses **TCP port 445**; some ISPs block it.
- If port 445 is blocked from your on‑prem location, you can:
  - Use **VPN/ExpressRoute** to an Azure VNet where SMB is allowed.
  - Or use **Azure File Sync** with an on‑prem Windows Server.

### 2. From Linux (SMB example)

```bash
sudo mount -t cifs //storageaccountname.file.core.windows.net/myshare /mnt/myshare \
  -o vers=3.0,username=storageaccountname,password=<storage_account_key>,dir_mode=0770,file_mode=0770
```

For NFS shares, you’d use `mount -t nfs` with the NFS endpoint and export path.

---

## F. Managing a File Share

### 1. Change Quota or Tier

- In the portal, open the file share → **Properties**.
- You can:
  - Increase the **quota** (if as-needed capacity grows).
  - Change **access tier** (transaction optimized ↔ hot ↔ cool) for standard SMB shares. citeturn0search11

### 2. Monitoring & Metrics

Use **Azure Monitor / Insights** for storage accounts:

- Check capacity, IOPS, latency.
- Configure alerts on **share capacity** approaching quota.
- Use **Azure Advisor** for performance and cost recommendations.

### 3. Data Protection Features

For the **file share** (or at storage account level), you can enable:

- **Share snapshots** – point-in-time copies of the share (see later file on snapshots).
- **Soft delete for file shares** – protect shares against accidental delete.
- **Azure Backup** – application-consistent backups and long-term retention.

These are configured mostly at **storage account → Data protection** and at **file share** level.

---

## G. Security & Best Practices (Exam Focus)

1. **Least privilege**:
   - Prefer **Azure AD / AD DS identity-based access**.
   - Avoid giving out **account keys** to users.

2. **Network security**:
   - Deny public network access when feasible.
   - Expose file shares via **private endpoints** into VNets.
   - Restrict access with **NSGs** and firewall rules.

3. **Data protection**:
   - Enable **soft delete for file shares** to protect share deletion.
   - Use **Azure Backup** for long-term retention and ransomware recovery.
   - Use **Azure File Sync** instead of direct scripting when you want on‑prem caching plus cloud backup.

4. **Performance**:
   - Use **Premium file shares** for high IOPS, low latency scenarios (AVD, databases).
   - Scale out with multiple shares when necessary; check scale targets and region limits.

---

## H. Exam-Style Scenarios

### Scenario 1

> Your company wants to migrate a Windows file server to Azure. Users must map drives with SMB, and the data must remain accessible from on‑premises and from Azure VMs. You want minimal management overhead. What do you use?

**Answer reasoning**:

- Need SMB, shared files, minimal management → **Azure Files**.
- To keep on‑prem caching and centralize in Azure → **Azure Files + Azure File Sync**.

### Scenario 2

> A VDI environment using AVD requires very low latency for user profile disks (FSLogix). Which Azure storage option should you choose?

**Answer**: **Premium Azure Files** (FileStorage account) file shares.

### Scenario 3

> You created a standard SMB Azure file share that is rarely accessed. You want to reduce storage cost at rest, and you don’t mind higher transaction costs. What should you change?

**Answer**: Change the share’s **access tier** to **Cool**.

---

## I. Quick Summary for the Exam

- Azure Files = **managed SMB/NFS file shares** in Azure.
- **Standard** vs **Premium** shares → cost vs performance.
- Standard SMB shares have **Transaction optimized / Hot / Cool** tiers.
- Decide **protocol (SMB/NFS)**, **quota**, **tier**, **redundancy**, and **networking** when creating a share.
- Use **private endpoints** + **firewall rules** for secure access.
- Use **identity-based access** with AD/Azure AD where possible.
- For on‑prem file server replacement → Azure Files (+ File Sync if you need caching).
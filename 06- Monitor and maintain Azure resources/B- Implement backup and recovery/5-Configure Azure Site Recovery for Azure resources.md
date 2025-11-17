# Configure Azure Site Recovery for Azure resources

Azure Site Recovery (ASR) is Azure’s **disaster recovery (DR)** solution.  
It replicates workloads to another location, so you can **fail over** during an outage and **fail back** when the primary site is healthy again.

In AZ‑104, the main focus is **Azure‑to‑Azure** replication for **Azure VMs**.  
You should understand:

- Core ASR concepts
- Prerequisites for VM replication
- How to configure replication using a Recovery Services vault
- Basic replication policy settings and monitoring


## 1. Azure Site Recovery concepts

### 1.1 What ASR does

- Continuously replicates VM disk data from a **source** region to a **target** region.
- Stores **recovery points** that you can use for failover.
- Allows **test failover**, **planned failover**, and **unplanned failover**.
- Supports:
  - Azure VM to Azure VM (cross‑region)
  - On‑premises VMware / Hyper‑V / physical servers to Azure (less important for AZ‑104).

### 1.2 Key components

- **Recovery Services vault**
  - Management container for ASR settings, metadata, and recovery points.
  - Same vault type that Azure Backup uses.
- **Source region**
  - Where the production VM currently runs.
- **Target region**
  - Where replicated data and failover VMs will be created.
  - Should be a supported **paired region** or another appropriate region.
- **Replication policy**
  - Defines:
    - **RPO** target (how often data is replicated).
    - **Retention** of recovery points.
    - Whether **app‑consistent snapshots** are captured.
- **Replication extension**
  - An agent or extension installed on the VM to send data to ASR.
  - For Azure‑to‑Azure, the **Site Recovery extension** is installed automatically when replication is enabled.

Simple mental picture:

```
[ VM in Region A ]
       |
       |  (continuous replication)
       v
[ Recovery Services vault + storage in Region B ]
       |
       |  (when failover is triggered)
       v
[ New VM in Region B ]
```


## 2. Prerequisites and planning

Before enabling replication, check the following:

### 2.1 Supported regions and pairings

- Ensure the **source and target regions** are supported for Azure‑to‑Azure disaster recovery.
- Prefer using **paired regions** (for example, West Europe ↔ North Europe).

### 2.2 Permissions

- To create a Recovery Services vault and configure ASR, you typically need:
  - **Owner** or **Contributor** rights on the subscription, or
  - Specific roles such as **Site Recovery Contributor** on the vault and resource groups.

### 2.3 Network and connectivity

- VMs must have outbound access to ASR endpoints (Azure service URLs).
- Plan **target virtual network and subnet**:
  - ASR will attach failed‑over VMs to this network.
  - Many organizations create a dedicated **DR VNet** in the target region.

### 2.4 Capacity and quotas

- Ensure you have enough **quota** in the target region:
  - VM cores
  - Storage
  - Network resources
- ASR will try to create a VM of the same size in the target region. If that size is not available, it chooses a compatible size.

### 2.5 Encryption and disks

- Check support for:
  - **Managed disks**
  - **Disk encryption** (for example, Azure Disk Encryption with Key Vault)
- Some advanced encryption scenarios require additional configuration.


## 3. Create or select a Recovery Services vault for Site Recovery

If you already created a Recovery Services vault for backup, you can also use it for ASR (though many organizations keep backup and DR in separate vaults).

### Steps

1. In the Azure portal, ensure a **Recovery Services vault** exists in the **target region** or the region where ASR metadata will be kept (often the target region).
2. If not, create one as described in the *Create a Recovery Services vault* file:
   - Use **Business Continuity Center ➜ Manage ➜ Vaults ➜ + Vault ➜ Recovery Services vault**.
3. Open the vault and note:
   - **Region**
   - **Resource group**
   - **Vault name**

This vault will store replication settings and recovery points.


## 4. Enable replication for Azure VMs (Azure‑to‑Azure)

There are two common approaches:

- From the **VM** blade (Disaster recovery).
- From the **Recovery Services vault** or Business Continuity Center.

### 4.1 From the VM blade (Disaster recovery)

1. Go to **Virtual machines** in the Azure portal.
2. Select the VM you want to protect.
3. In the left menu, look for **Backup + disaster recovery ➜ Disaster recovery** (or simply **Disaster recovery**).
4. The **Disaster recovery** page shows:
   - **Source region** (current region of the VM).
   - **Target region** (auto‑suggested paired region or a region you can choose).
5. Configure **Target settings**:
   - **Target subscription**
   - **Target resource group**
   - **Target virtual network and subnet**
   - **Target availability options** (zone, availability set, or none)
6. Review **Replication policy**:
   - Default policy might have:
     - RPO target (for example, 15 minutes).
     - Retention period for recovery points.
     - App‑consistent snapshot frequency.
   - You can usually choose an existing policy or create a new one.
7. Click **Review + start replication**.
8. ASR will:
   - Install the **Site Recovery extension** on the VM.
   - Start initial replication (full sync of disk data).
   - Then move to **continuous replication**.

It may take some time for initial replication to complete, depending on data size and network throughput.

### 4.2 From the Recovery Services vault

1. Open the **Recovery Services vault**.
2. Under **Protect + replicate**, select **+ Enable replication** or **+ Replicate**.
3. Select **Source**:
   - **Source type**: *Azure*.
   - **Source location**: the region of the existing VMs.
   - **Source subscription** and **resource group**.
4. Select **Target**:
   - **Target location** (the DR region).
   - **Target subscription / resource group**.
   - **Target VNet and subnet**.
5. On the **Virtual machines** tab, select one or more VMs.
6. On the **Replication settings** tab:
   - Choose or create a **Replication policy**.
7. Start replication.

This method is useful to enable replication for many VMs at once.

---

## 5. Replication policy details

A **replication policy** controls:

- **Recovery point objective (RPO)** target — how often data is replicated.
- **Retention** of recovery points.
- **Synchronization** settings.

Typical settings you may see:

- **RPO threshold**: for example, 15 minutes.
- **Recovery point retention**: several hours or days.
- **App‑consistent snapshot frequency**: for example, every 4 hours.

**App‑consistent recovery points**:

- Capture data in a state where the OS and applications have flushed buffers.
- Better for recovering complex apps (databases, etc.) than crash‑consistent points.

In the portal:

- You can view policies under **Recovery Services vault ➜ Site Recovery ➜ Replication policies**.
- You can create a new policy and then associate it with VMs or replication groups.


## 6. Monitoring replication health

Once replication is enabled:

- Each VM shows a **Replication health** status:
  - `Healthy`
  - `Warning`
  - `Critical`
  - `Not protected`
- You can monitor from:
  - The **Recovery Services vault**:
    - **Site Recovery ➜ Replicated items**
  - The **VM blade ➜ Disaster recovery** pane
  - **Business Continuity Center** for a global view

Common issues:

- **Networking** problems (VM cannot reach ASR endpoints).
- **Insufficient storage/quota** in target region.
- **Extensions** failing on the VM.

When an issue occurs:

- Check the **Jobs** and **replication events** in the vault.
- Use the **Details** or **Errors** section for troubleshooting hints.


## 7. Example: Configure DR for a production VM

Scenario:

- VM `vm-prod-web1` in `West Europe`.
- Need DR to `North Europe` with an RPO of 15 minutes.
- Target network `vnet-prod-dr-neu`.

Steps summary:

1. Create or confirm a **Recovery Services vault** in `North Europe`.
2. In the VM’s blade:
   - Open **Disaster recovery**.
   - Select `North Europe` as **Target region**.
   - Choose target subscription/RG and `vnet-prod-dr-neu`.
3. Choose a **replication policy**:
   - RPO 15 minutes.
   - App‑consistent snapshots every few hours.
   - Recovery point retention for, say, 24 hours.
4. Start replication.
5. Monitor **initial replication** until the status becomes **Protected** and **Healthy**.
6. Optionally run a **test failover** to confirm everything works (covered in the next file).


## 8. Where Azure Site Recovery fits with Backup

You’ll often see ASR and Azure Backup together:

- **Azure Backup (vault)**:
  - Protects data for restore to previous points in time (corruption, deletion, ransomware).
  - Focused on **long‑term retention** and **item‑level restore**.

- **Azure Site Recovery (same or another vault)**:
  - Handles **business continuity** – keeping your application running in another region if the primary fails.
  - Focused on **low RPO/RTO**, not long‑term retention.

It’s a common best practice to use **both**:

- Backup for **restore**.
- Site Recovery for **failover**.

---

### Quick review

For AZ‑104, make sure you can answer:

- What is Azure Site Recovery and what is it used for?
- What is the **source region** and **target region**?
- What does a **replication policy** define?
- What are the basic steps to **enable replication** for an Azure VM?
- Where do you check **replication health**?

If you can explain these steps to someone else, you’re in good shape for Site Recovery configuration questions.

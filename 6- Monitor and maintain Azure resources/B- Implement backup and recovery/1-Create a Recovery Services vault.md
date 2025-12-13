# Create a Recovery Services vault

## 1. Concept and purpose

A **Recovery Services vault (RSV)** is a special Azure resource used by:

- **Azure Backup** – to store backup data and recovery points.
- **Azure Site Recovery (ASR)** – to store replication metadata and recovery points for disaster recovery.

You can think of the vault as:

> A secure, managed container where Azure keeps your backup copies and disaster‑recovery information.

Typical workloads that use a Recovery Services vault:

- Azure Virtual Machines (Windows and Linux)
- Azure Files shares
- SQL Server / SAP HANA running inside Azure VMs
- On‑premises Windows/Linux servers, protected with:
  - MARS agent (Microsoft Azure Recovery Services agent)
  - Microsoft Azure Backup Server (MABS) or System Center DPM
- Azure Site Recovery for:
  - Azure VM to Azure VM (cross‑region)
  - VMware / Hyper‑V / physical servers to Azure

### Recovery Services vault vs Backup vault (high‑level)

Azure now has **two** vault types:

| Vault type            | Main workloads                             | Platform                         |
|-----------------------|--------------------------------------------|----------------------------------|
| **Recovery Services** | Azure VMs, Azure Files, SQL in VMs, ASR   | “Classic” Azure Backup platform |
| **Backup vault**      | Newer workloads (disks, blobs, DBs, etc.) | Azure Data Protection platform   |

For AZ‑104, remember:

- If the question talks about **VM backup** or **Azure Site Recovery**, think **Recovery Services vault**.
- If it talks about **Azure Disk Backup**, **Azure Blob backup**, or **modern vaulted backups**, think **Backup vault**.


## 2. Design decisions before creating the vault

### 2.1 Region

- The vault is **regional**. For most workloads, the vault must be in the **same region** as the protected resources.
  - Example: VMs in `West Europe` → vault in `West Europe`.
- If you have VMs in both `West Europe` and `East US`, you normally need **two vaults**, one per region.

**Exam pattern**

> “VMs in multiple regions must be backed up to a vault in the same region as the VM.”  
> Answer: **Create one Recovery Services vault per region.**

### 2.2 Subscription, resource group, and naming

- The vault lives in **one subscription** and **one resource group**.
- Good practice: dedicate a resource group for BCDR resources, for example:
  - `rg-prod-bcdr-weu`
- Follow a clear naming convention, for example:
  - `rsv-prod-weu-01`
  - `rsv-test-weu-01`

This makes it easy to:

- Delegate access (RBAC) at vault or RG level.
- See at a glance which vault protects which environment.

### 2.3 Storage redundancy (LRS / ZRS / GRS)

A Recovery Services vault uses Azure Storage behind the scenes. You choose the redundancy level:

- **LRS (Locally Redundant Storage)**
  - 3 copies in a single datacenter in one region.
  - Cheapest, but no zone or regional protection.

- **ZRS (Zone‑Redundant Storage)**
  - Copies across different **Availability Zones** in one region.
  - Protects from a single datacenter/zone failure.

- **GRS (Geo‑Redundant Storage)**
  - Copies data to a **paired region**.
  - Highest durability; enables features like **Cross‑Region Restore (CRR)**.

> Important: choose redundancy **before** enabling backup.  
> Once any item is protected, you can’t change redundancy for that vault.  
> To switch, you must create a **new vault** and re‑enable backup.

### 2.4 Security settings

Key security features on a Recovery Services vault:

- **Soft delete**
  - Enabled by default on new vaults.
  - When you stop protection and delete data, backup items go into a *soft‑delete* state for a period (e.g., 14 days).
  - You can recover deleted backups during that period.
  - Protects against accidental and malicious deletion (for example, ransomware).

- **Immutability**
  - Option to make recovery points **undeletable** until their retention period expires.
  - Can be:
    - **Unlocked** – changes allowed.
    - **Locked** – configuration is frozen; strong protection but less flexible.

- **Multi‑user authorization (MUA) / Resource Guard**
  - Critical operations (for example, turning off soft delete or deleting the vault) can require approval from a different identity.
  - This reduces the risk of a single compromised account wiping backups.

### 2.5 Encryption

- By default, Azure uses **platform‑managed keys (PMK)** to encrypt vault data.
- You can optionally choose **customer‑managed keys (CMK)** stored in Azure Key Vault:
  1. Enable a **managed identity** on the vault.
  2. Grant the identity permissions on a key in your Key Vault.
  3. Configure the vault to use that key for encryption.
- Decide this at the start; switching between PMK and CMK later is restricted once backups exist.


## 3. Creating a Recovery Services vault in the Azure portal

You can create vaults through:

- **Business Continuity Center** (new unified experience), or
- **Backup center** / **Recovery Services vaults** blades (still seen in older docs and exam questions).

### 3.1 Using Business Continuity Center (recommended)

1. Sign in to the **Azure portal**.
2. In the search bar, type **“Business Continuity Center”** and open it.
3. In the left menu, go to **Manage ➜ Vaults**.
4. Select **+ Vault**.
5. On **Start: Create Vault**, choose **Recovery Services vault**, then select **Continue**.
6. Fill in the **Basics** tab:
   - **Subscription**
   - **Resource group**
   - **Vault name**
   - **Region**
7. On **Storage and security**, choose:
   - **Storage redundancy**: LRS / ZRS / GRS
   - Whether to enable:
     - **Soft delete**
     - **Immutability**
     - **Cross‑Region Restore**, if GRS is selected.
8. Select **Review + create**, then **Create**.

Deployment typically takes less than a minute. After it finishes, you can:

- Go back to **Business Continuity Center ➜ Vaults**, or
- Search directly for **“Recovery Services vaults”** to open the new vault.

### 3.2 Using the Recovery Services vaults blade

1. In the portal search box, type **“Recovery Services vaults”**, open it.
2. Click **+ Create**.
3. Choose:
   - Subscription
   - Resource group
   - Vault name
   - Region
4. Configure storage/security if the wizard exposes those options.
5. Select **Review + create** ➜ **Create**.

> Exam note  
> Questions may use either “Backup center” or “Business Continuity Center” in the UI path.  
> The main idea: **create a Recovery Services vault, pick the right region, redundancy, and security settings**.


## 4. Important configuration after vault creation

Before you protect any items, go through these settings once.

### 4.1 Verify storage redundancy

1. Open the vault.
2. Under **Settings**, select **Properties**.
3. Look for **Backup configuration**.
4. Confirm the redundancy (LRS / ZRS / GRS) is what you need.

If it’s wrong and no items are yet protected:

- You can still change redundancy (in newer experiences) **if** the vault has no backup items.
- Once any resource is protected, treat that redundancy as permanent.

### 4.2 Configure soft delete and immutability

1. In the vault, go to **Properties ➜ Security settings**.
2. Ensure **Soft delete** is **On** (recommended).
3. Configure **Immutability** if required by security/compliance.
4. If you must temporarily disable soft delete (for example during migration), do it here, and re‑enable it later.

### 4.3 Enable Cross‑Region Restore (optional)

- If your vault uses **GRS**:
  1. Go to **Properties ➜ Backup configuration**.
  2. Turn **Cross‑Region Restore** **On**.
  3. Save changes.
- This lets you restore to the **paired region** even when the primary region is healthy, which is useful for DR testing.

### 4.4 Set up RBAC

Use Azure RBAC roles for least privilege:

- **Backup Contributor** – can manage backup but not the vault itself.
- **Site Recovery Contributor** – manage Site Recovery operations.
- **Reader** – view status.

You can assign roles at:

- Subscription level
- Resource group level
- Vault level

AZ‑104 is about understanding **role scope** and **least privilege** more than memorizing role names.


## 5. Creating a Recovery Services vault with CLI and PowerShell

The exam focuses on concepts and portal steps, but it helps to recognize basic CLI/PowerShell commands.

### 5.1 Azure CLI example

```bash
# Variables
RESOURCE_GROUP="rg-prod-bcdr-weu"
LOCATION="westeurope"
VAULT_NAME="rsv-prod-weu-01"

# Create resource group (if needed)
az group create       --name "$RESOURCE_GROUP"       --location "$LOCATION"

# Create the Recovery Services vault
az backup vault create       --name "$VAULT_NAME"       --resource-group "$RESOURCE_GROUP"       --location "$LOCATION"

# Set backup storage redundancy (before enabling backups)
az backup vault backup-properties set       --name "$VAULT_NAME"       --resource-group "$RESOURCE_GROUP"       --backup-storage-redundancy GeoRedundant  # or LocallyRedundant / ZoneRedundant
```

Key points:

- `az backup vault create` creates the vault.
- `az backup vault backup-properties set` configures redundancy.

### 5.2 PowerShell example

```powershell
$resourceGroup = "rg-prod-bcdr-weu"
$location      = "West Europe"
$vaultName     = "rsv-prod-weu-01"

# Create the vault
New-AzRecoveryServicesVault `
  -Name $vaultName `
  -ResourceGroupName $resourceGroup `
  -Location $location

# Configure storage redundancy
$vault = Get-AzRecoveryServicesVault -Name $vaultName

Set-AzRecoveryServicesBackupProperties `
  -Vault $vault `
  -BackupStorageRedundancy GeoRedundant   # or LocallyRedundant / ZoneRedundant
```

If a question shows one of these commands, you should be able to recognize:

- That they are **creating a Recovery Services vault**.
- That they are setting **backup storage redundancy**.


## 6. Common exam scenarios and gotchas

### 6.1 Changing redundancy after backups exist

- **Scenario:** You created a vault with LRS and started backing up VMs. Now you want GRS.
- **Reality:** You **cannot** change redundancy while backups exist.
  - Solution: create a **new vault** with GRS and re‑enable backup for those VMs.

### 6.2 Moving vaults

- You can move a Recovery Services vault between **resource groups** or **subscriptions** in some cases.
- You **cannot move** it to another **region**.
- You also can’t “merge” two vaults or move backup data from one to another.

### 6.3 Number of vaults

- You can have multiple vaults per subscription and region.
- Typical patterns:
  - One vault for **production** and one for **non‑production**, per region.
  - Separate vaults for **backup** and **site recovery** if you want different management or security boundaries.

### 6.4 Vault and VM region mismatch

- A very common exam trap:
  - If the VM is in `North Europe` and the vault is in `West Europe`, you **can’t** back that VM up to that vault.
  - You must create or use a vault in **North Europe**.

### 6.5 No extra storage account required

- For most cloud‑only workloads, you don’t create a separate storage account for backup data.
- Azure Backup manages storage **inside the vault**.

---

## 7. Quick summary

If you remember these points, you’ll answer most “Create a Recovery Services vault” questions:

- A Recovery Services vault is a **regional** Azure resource used by **Azure Backup** and **Azure Site Recovery**.
- Place the vault **in the same region** as the resources you protect.
- Decide early on:
  - **Redundancy** (LRS / ZRS / GRS)
  - **Security** (soft delete, immutability, MUA)
  - **Encryption** (PMK vs CMK)
- Create the vault via:
  - **Business Continuity Center ➜ Manage ➜ Vaults ➜ + Vault ➜ Recovery Services vault**, or
  - The **Recovery Services vaults** blade.
- You **can’t change redundancy** once backup items exist, and you **can’t move** backup data between vaults.

Learn this flow once and reuse it mentally for any Azure Backup or Site Recovery configuration in the exam.

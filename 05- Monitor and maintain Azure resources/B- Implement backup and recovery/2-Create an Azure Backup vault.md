# Create an Azure Backup vault

## 1. What is an Azure Backup vault?

A **Backup vault** is a newer type of vault used by Azure Backup’s **modern data protection platform** (Azure Data Protection).

It is designed for **newer workloads**, such as:

- Azure Managed Disks (Azure Disk Backup)
- Azure Blobs (vaulted backup for block blobs and Data Lake Storage Gen2)
- Azure Database for PostgreSQL (Flexible Server)
- Azure Kubernetes Service (AKS) backup extension
- Other “Data Protection–based” workloads that will appear over time

Key points:

- Backup vaults are resources of type `Microsoft.DataProtection/backupVaults`.
- Functionally similar idea to a Recovery Services vault (they store backup data and policies).
- Optimized for:
  - Large scale
  - Modern workloads
  - Deep integration with Azure Monitor, Azure Policy, and Business Continuity Center.

> For AZ‑104, you **don’t** need to master every Data Protection feature.  
> You *do* need to understand the **difference** between a **Recovery Services vault** and a **Backup vault**, and how to create a Backup vault.


## 2. Recovery Services vault vs Backup vault

| Aspect                         | Recovery Services vault                            | Backup vault                                      |
|--------------------------------|----------------------------------------------------|--------------------------------------------------|
| Resource type                  | `Microsoft.RecoveryServices/vaults`                | `Microsoft.DataProtection/backupVaults`          |
| Typical workloads              | Azure VMs, Azure Files, SQL/SAP in VMs, ASR       | Disks, Blobs, PostgreSQL Flexible, AKS, etc.     |
| Tech platform                  | “Classic” Azure Backup                             | Data Protection platform                         |
| Site Recovery support          | Yes (ASR)                                          | No – for backup only                             |
| Where created / managed        | BCC / Backup center / RSV blade                    | BCC / Backup center / Backup vault blade         |

Use this simple rule in the exam:

- If the question says **disk snapshots**, **vaulted backup of blobs/databases**, or **Data Protection**, you likely need a **Backup vault**.
- If it says **VM backup** or **Site Recovery**, you likely need a **Recovery Services vault**.


## 3. Design decisions for a Backup vault

### 3.1 Region and resource group

- A Backup vault is **regional**.
- It should be in the **same region as the data source** you want to protect (for example, disks or storage accounts).
- Use a clear resource group naming convention, for example:
  - `rg-prod-bcdr-weu`
- Use a meaningful vault name, for example:
  - `bkv-prod-weu-01`

### 3.2 Storage settings

When you create a Backup vault, you define **storage settings**:

- **Redundancy** (LRS, ZRS, GRS).
- Some workloads support different tiers (for example operational vs vaulted backups).

Similar to a Recovery Services vault:

- Once workloads are protected, changing redundancy is restricted.
- Planning is important.

### 3.3 Security: soft delete, immutability, cross‑subscription restore

Backup vaults support:

- **Soft delete**
  - Protects against accidental/malicious deletion.
  - Deleted backups are retained in a soft‑delete state for a defined period.

- **Immutability**
  - Prevents tampering with recovery points until their retention expires.
  - Can be locked for strict compliance.

- **Cross‑subscription restore**
  - Allows restoring data into a different subscription in the same tenant.

- **Integration with Resource Guard**
  - To require additional approvals for critical operations (multi‑user authorization).


## 4. Create a Backup vault in the Azure portal

As with Recovery Services vaults, the modern entry point is **Business Continuity Center**.

### 4.1 Using Business Continuity Center

1. Sign in to the **Azure portal**.
2. Open **Business Continuity Center** from the global search.
3. In the left menu, go to **Manage ➜ Vaults**.
4. Select **+ Vault**.
5. On **Start: Create Vault**, choose **Backup vault**, then **Continue**.
6. On the **Basics** tab:
   - Select **Subscription**.
   - Choose or create a **Resource group**.
   - Enter a **Vault name** (e.g., `bkv-prod-weu-01`).
   - Select the **Region**.
7. On **Storage and security**:
   - Choose **storage redundancy** (LRS / ZRS / GRS).
   - Configure **soft delete**, **immutability**, and **cross‑subscription restore** as required.
8. Click **Review + create**, then **Create**.

After deployment, you can see the vault:

- Under **Business Continuity Center ➜ Vaults**, or
- By searching for **“Backup vaults”** in the portal.

### 4.2 Using the Backup vaults blade

There’s also a dedicated blade for Backup vaults:

1. Search for **“Backup vaults”**.
2. Select **+ Create**.
3. Fill in **Basics** (subscription, RG, name, region).
4. Configure **Storage and security**.
5. **Review + create ➜ Create**.


## 5. Create a Backup vault with Azure CLI

Backup vaults are managed by the `dataprotection` extension in Azure CLI.

### 5.1 Install the extension (if needed)

```bash
az extension add --name dataprotection
```

### 5.2 Create the Backup vault

Example:

```bash
RESOURCE_GROUP="rg-prod-bcdr-weu"
LOCATION="westeurope"
VAULT_NAME="bkv-prod-weu-01"

# Create the resource group (if needed)
az group create       --name "$RESOURCE_GROUP"       --location "$LOCATION"

# Define storage settings as JSON.
# Example: one setting, GeoRedundant.
STORAGE_SETTINGS='[
  {
    "type": "GeoRedundant",
    "datastoreType": "VaultStore"
  }
]'

# Create the Backup vault
az dataprotection backup-vault create       --resource-group "$RESOURCE_GROUP"       --vault-name "$VAULT_NAME"       --location "$LOCATION"       --storage-settings "$STORAGE_SETTINGS"
```

Notes:

- `datastoreType` is usually `VaultStore` for vaulted backups.
- For LRS, use `"type": "LocallyRedundant"`; for ZRS, `"ZoneRedundant"` if supported.

You can view the vault later with:

```bash
az dataprotection backup-vault show       --resource-group "$RESOURCE_GROUP"       --vault-name "$VAULT_NAME"
```


## 6. Create a Backup vault with PowerShell

Backup vaults are managed by the `Az.DataProtection` module.

```powershell
Install-Module -Name Az.DataProtection -Scope CurrentUser -Force

$resourceGroup = "rg-prod-bcdr-weu"
$location      = "West Europe"
$vaultName     = "bkv-prod-weu-01"

# Example storage settings – GeoRedundant VaultStore
$storageSettings = @(
  @{
    type          = "GeoRedundant"
    datastoreType = "VaultStore"
  }
)

New-AzDataProtectionBackupVault `
  -ResourceGroupName $resourceGroup `
  -VaultName $vaultName `
  -Location $location `
  -StorageSetting $storageSettings
```

In newer cmdlets, you can also pass properties for:

- Soft delete
- Immutability
- Cross‑subscription restore

at creation time.


## 7. After the Backup vault is created

Once the vault exists, you can:

- Create **backup policies** for supported workloads.
- Configure **backup instances** (for example, for disks or blobs).
- Configure **monitoring and alerts** through Business Continuity Center and Azure Monitor.

Portal path (examples):

- For disks: **Backup vault ➜ Backup policies / Backup instances ➜ Add**.
- For blobs: go to the **storage account ➜ Backup** and choose the Backup vault and policy.

The exact UI changes over time, but the pattern is:

1. **Create a Backup vault.**
2. **Create a policy** in that vault for a specific data source type.
3. **Associate** data sources (disks, storage accounts, DB servers) with that policy.


## 8. Exam scenarios and hints

1. **“You must back up Azure managed disks with centralized management and vaulted copies.”**  
   → Use **Azure Disk Backup** with a **Backup vault**.

2. **“You must configure vaulted backup of Azure Blobs with granular scheduling and retention.”**  
   → Use **Backup vault + Blob backup** (Data Protection).

3. **“You must back up Azure VMs and enable Site Recovery.”**  
   → Still a **Recovery Services vault**, not a Backup vault.

4. **Region requirement**  
   - The vault must be in the **same region** as the data source (for example, the disks or storage account).

5. **Migration between vault types**  
   - There is no “convert Recovery Services vault to Backup vault” button.
   - Treat them as different resource types for different workloads.

---

### Quick memory trick

- **Recovery Services vault**  
  > “Old‑school hero” – backs up VMs and does Site Recovery.

- **Backup vault**  
  > “New kid” – focuses on modern workloads (disks, blobs, DBs) with Data Protection.

If you can identify **which vault type a question needs** and know how to create it in the portal, you’ll be well‑prepared for this AZ‑104 skill.

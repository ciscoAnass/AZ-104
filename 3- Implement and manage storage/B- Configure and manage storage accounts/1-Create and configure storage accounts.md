
# Create and Configure Storage Accounts

## A. Storage account basics

### 1. What is a storage account?

A **storage account** is the top‑level Azure resource that gives you a unique namespace for data services like:

- **Blob Storage** – object storage for files, backups, images, logs.
- **Azure Files** – SMB / NFS file shares.
- **Queues** – message queues for apps.
- **Tables** – NoSQL key–value store (only in some account types).
- **Data Lake Storage Gen2** – big‑data analytics on top of Blob (hierarchical namespace).

Think of a storage account as a **“container for services + settings”**:

- The account decides:
  - Region
  - Redundancy (LRS/ZRS/GRS/…)
  - Performance (Standard/Premium)
  - Network rules & security
  - Encryption defaults
  - Data protection features (soft delete, versioning, etc.)

All data under that account shares those core settings.

---

### 2. Why it matters for AZ‑104

On the exam you must be able to:

- Choose the **right account type** for a scenario.
- Configure:
  - Redundancy
  - Access & network
  - Data protection
  - Encryption
- Create and manage accounts with **Portal, CLI, PowerShell, ARM/Bicep**.
- Understand **limits and trade‑offs** (e.g., when ZRS/Archive are allowed, when to use Data Lake Gen2, etc.).

---

## B. Storage account types and performance

### 1. Account types (kind)

These are the main storage account kinds you’ll see today:

| Account kind          | Typical use cases                                                                 |
|-----------------------|------------------------------------------------------------------------------------|
| **General-purpose v2 (GPv2)** | Default & recommended for most workloads. Supports blobs, files, queues, tables, Data Lake Gen2, hot/cool/archive, all redundancy options (depends on region). |
| **Premium block blob** | High‑performance block blobs (low latency, high throughput). Good for streaming, ingestion, big analytics workloads. |
| **Premium file shares (FileStorage)** | Premium Azure Files with SSD, consistent low latency for file shares. |
| **Premium page blobs** | Used mainly by Azure managed disks (VM OS/data disks). |

Legacy types (GPv1, BlobStorage) may still show up, but **for design questions always prefer GPv2** unless the scenario clearly needs a premium account.

---

### 2. Performance tiers

**Standard (HDD‑backed)**

- Backed by HDD storage.
- Lower cost, higher latency.
- Supports:
  - Blob (hot/cool/archive)
  - Azure Files (standard file shares)
  - Queues & Tables (GPv2)
- Best for general workloads and large capacity.

**Premium (SSD‑backed)**

- Backed by SSD.
- High IOPS, low latency.
- Premium account types:
  - **Premium block blob**
  - **Premium FileStorage**
  - **Premium page blob (disks)**
- Premium usually supports fewer redundancy options and may have capacity limits per share/container, but much better performance.

**Exam tip**

- **“Low latency” or “high IOPS”** → think **Premium**.
- **“Lowest cost, infrequent access, archives”** → think **Standard GPv2 + Cool/Archive tiers**.

---

## C. Naming, endpoints, and resource model

### 1. Naming rules

Storage account name:

- 3–24 characters.
- Lowercase letters and numbers only.
- Must be **globally unique** across Azure (because it’s used in DNS).
- Cannot contain spaces, uppercase, or special characters.

Example: `rabbitchatstorage01`

### 2. Endpoints

Each storage service gets an endpoint based on the account name:

- Blob: `https://<account>.blob.core.windows.net`
- File: `https://<account>.file.core.windows.net`
- Queue: `https://<account>.queue.core.windows.net`
- Table: `https://<account>.table.core.windows.net`
- Data Lake Gen2 (hierarchical namespace): same blob endpoint with additional capabilities.

Objects under the account simply append to this URL:

```text
https://mystorageacc.blob.core.windows.net/mycontainer/myblob.txt
```

### 3. Resource model

A storage account lives inside:

- A **subscription**
- A **resource group**
- A **region**

Region choice affects:

- **Latency** (closer to users/apps is better).
- Available **redundancy options** (ZRS/GZRS not in all regions).
- Paired region for **geo‑redundancy**.

---

## D. Access tiers for blob data

Access tiers control **cost vs. frequency of access** for **blob data**:

| Tier     | Optimized for                        | Typical use                                  |
|----------|--------------------------------------|----------------------------------------------|
| **Hot**  | Frequent access, lowest latency      | Active data, web content, transactional apps |
| **Cool** | Infrequent access (≥30 days)         | Backups, short‑term archives, logs           |
| **Archive** | Very infrequent (months/years). Highest latency because data must be rehydrated. | Long‑term archival, compliance data          |

Key points:

- The **account** has a **default access tier** (Hot or Cool) for new blobs.
- You can set the tier **per blob**, overriding the account default.
- **Archive** tier is **only for blobs**, not for files.
- Some redundancy options do **not** support archive directly (e.g., ZRS/GZRS/RA‑GZRS limitations), so you may need to plan around that.

**Exam scenarios**

- “Data read a lot in a web app” → **Hot**.
- “Backups rarely accessed but must be online” → **Cool**.
- “Legal archive, must keep 7 years, rarely read” → **Archive**.

---

## E. Key configuration options when creating a storage account

When you create a storage account (Portal, CLI, PowerShell), you must choose:

1. **Region**
2. **Performance** (Standard / Premium)
3. **Redundancy** (LRS/ZRS/GRS/RA‑GRS/GZRS/RA‑GZRS)
4. **Account kind** (GPv2, Premium block blob, FileStorage, etc.)
5. **Networking model** (public endpoint, firewalls/VNet, private endpoints)
6. **Data protection settings**
7. **Encryption options**
8. **Advanced features** (large file shares, hierarchical namespace, NFS, etc.)

Let’s go through the big ones for the exam.

---

### 1. Networking configuration

You mainly configure:

- **Public network access**:
  - **Enabled from all networks** – open to any IP (still needs auth).
  - **Enabled from selected virtual networks and IP addresses** – restricts access to specific VNets and/or IP ranges.
  - **Disabled** – require **private endpoints**.

- **Storage firewall rules**:
  - Allow specific **public IPs** or **IP ranges**.
  - Allow traffic only from selected **VNets** via service endpoints or private endpoints.

- **Secure transfer required**:
  - Forces HTTPS (no HTTP).
  - For Azure Files, forces SMB 3.0 over encrypted channels.

- **Minimum TLS version**:
  - Supported: TLS 1.0, 1.1, 1.2, 1.3.
  - Recommended minimum for new solutions: **TLS 1.2**.
  - Clients negotiate highest available version.

**Exam tips**

- “Block legacy clients using TLS 1.0/1.1” → set **Minimum TLS version = 1.2**.
- “Only allow access from on‑prem IP range and one VNet” → use **firewall + VNet rules**.
- “Only allow internal private IPs, no public endpoint at all” → use **private endpoint + disable public access**.

---

### 2. Data protection features (Portal → Data protection)

These settings are **per storage account** but mostly affect **blobs** and **file shares**:

**For blobs**

- **Soft delete for blobs** – keep deleted blobs for X days (e.g., 7–365).
- **Soft delete for containers** – recover deleted containers.
- **Blob versioning** – automatically keep previous versions of blobs.
- **Change feed** – immutable log of all blob changes (useful for analytics, replication, and audits).
- **Point‑in‑time restore** – restore a container to an earlier state (depends on versioning and change feed).

**For file shares (Azure Files)**

- **Share soft delete** – retain deleted shares.
- **Point‑in‑time restore for shares** – restore share to a previous state (premium and/or specific regions/features).

These are critical for:

- **Recovering from accidental deletes/overwrites.**
- Enabling advanced features like **object replication** (requires versioning + change feed).

**Exam tip**

If the question is about **recovering accidentally deleted or overwritten blobs**, think:

- Blob versioning
- Blob soft delete
- Container soft delete
- Point‑in‑time restore

Use the simplest feature that satisfies the scenario.

---

### 3. Advanced features

When creating or configuring the account:

- **Large file shares** – increase file share capacity and IOPS for Azure Files.
- **Hierarchical namespace (HNS)** – enables **Data Lake Storage Gen2** features:
  - Folders/directories
  - POSIX‑style ACLs
  - Better analytics scenarios
- **NFS 3.0** for blobs – object storage over NFS protocol (requires specific account configuration).
- **Azure Active Directory authentication**:
  - For blob and file access (RBAC + identity‑based auth).

**Important**

- Enabling **hierarchical namespace** (Data Lake Gen2) is **one‑way**: once on, you cannot turn it off.
- Some features (like object replication) have restrictions when HNS is enabled.

---

## F. Creating a storage account – Azure Portal

1. Go to **Azure portal** → **Storage accounts** → **Create**.
2. **Basics** tab:
   - Subscription
   - Resource group
   - Storage account name
   - Region
   - Performance (Standard/Premium)
   - Redundancy (LRS/ZRS/GRS/GZRS/RA‑GRS/RA‑GZRS)
3. **Advanced** tab:
   - Require secure transfer (HTTPS)
   - Minimum TLS version
   - Enable large file shares
   - Hierarchical namespace (Data Lake Gen2)
   - NFS, SFTP, etc. (if supported/needed)
4. **Networking** tab:
   - Public network access (all / selected networks / disabled)
   - Firewall IP rules
   - Virtual networks / private endpoints
   - Routing preferences (Microsoft network vs Internet routing)
5. **Data protection** tab:
   - Soft delete (blobs, containers, file shares)
   - Blob versioning
   - Change feed
   - Point‑in‑time restore
6. **Encryption** tab:
   - Encryption type: Microsoft‑managed key vs Customer‑managed key (Key Vault/HSM)
   - Encryption scopes options
   - Infrastructure encryption (double encryption) if required
7. **Review + create** → check **Validation passed** → **Create**.

---

## G. Creating a storage account – Azure CLI

### 1. Basic example

```bash
# Variables
RG="rg-az104-lab"
LOC="westeurope"
ACCOUNT="az104storagexyz"

az group create -n $RG -l $LOC

az storage account create \
  --name $ACCOUNT \
  --resource-group $RG \
  --location $LOC \
  --sku Standard_LRS \
  --kind StorageV2 \
  --access-tier Hot \
  --https-only true \
  --min-tls-version TLS1_2
```

Key parameters:

- `--sku` → redundancy + performance (e.g., `Standard_LRS`, `Standard_ZRS`, `Standard_GRS`, `Premium_LRS`).
- `--kind` → `StorageV2` (GPv2), `BlockBlobStorage`, `FileStorage`.
- `--access-tier` → `Hot` or `Cool` (default tier for blobs).
- `--https-only` → secure transfer required.
- `--min-tls-version` → TLS minimum.

### 2. Enabling advanced features with CLI

**Hierarchical namespace (Data Lake Gen2)**:

```bash
az storage account create \
  --name $ACCOUNT \
  --resource-group $RG \
  --location $LOC \
  --sku Standard_LRS \
  --kind StorageV2 \
  --https-only true \
  --hierarchical-namespace true
```

**Enable large file shares** (for Azure Files):

```bash
az storage account update \
  --name $ACCOUNT \
  --resource-group $RG \
  --enable-large-file-share
```

**Configure firewall and allowed IPs**:

```bash
az storage account update \
  --name $ACCOUNT \
  --resource-group $RG \
  --default-action Deny

az storage account network-rule add \
  --resource-group $RG \
  --account-name $ACCOUNT \
  --ip-address 203.0.113.10
```

---

## H. Creating a storage account – PowerShell

```powershell
$rg = "rg-az104-lab"
$loc = "West Europe"
$account = "az104storagexyz"

New-AzResourceGroup -Name $rg -Location $loc

New-AzStorageAccount `
  -ResourceGroupName $rg `
  -Name $account `
  -Location $loc `
  -SkuName Standard_LRS `
  -Kind StorageV2 `
  -AccessTier Hot `
  -EnableHttpsTrafficOnly $true `
  -MinimumTlsVersion TLS1_2
```

To enable hierarchical namespace:

```powershell
New-AzStorageAccount `
  -ResourceGroupName $rg `
  -Name $account `
  -Location $loc `
  -SkuName Standard_LRS `
  -Kind StorageV2 `
  -EnableHierarchicalNamespace $true
```

---

## I. Creating a storage account – ARM/Bicep (high level)

### 1. Bicep example

```bicep
param storageAccountName string
param location string = resourceGroup().location

resource sa 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
      ipRules: [
        {
          action: 'Allow'
          value: '203.0.113.10'
        }
      ]
    }
  }
}
```

You should be able to **read and understand** such templates for the exam:

- Recognize the resource type `Microsoft.Storage/storageAccounts`.
- Identify properties: redundancy (SKU), access tier, HTTPS only, network rules, etc.
- Know how to change them if asked (modify JSON/Bicep).

---

## J. Managing an existing storage account

Common tasks:

- **Update TLS or secure transfer settings**:
  - Portal → Storage account → Settings → Configuration.
  - CLI: `az storage account update --https-only true --min-tls-version TLS1_2`.

- **Modify network access**:
  - Portal → Networking tab.
  - CLI: `az storage account network-rule ...`.

- **Change redundancy**:
  - Some redundancy changes allowed without re‑creating the account (e.g., LRS → GRS, GRS ↔ RA‑GRS; region and account type limitations apply).
  - Others might require migration or data copy to a new account.

- **Move account to another resource group or subscription**:
  - Allowed if source and target are in the **same region** and same tenant.
  - Portal: `Move` action on the storage account.
  - Some features may temporarily be unavailable during move.

---

## K. Exam tips & scenario patterns

1. **“Need cheapest storage for backups that are rarely accessed”**  
   → Standard GPv2, LRS or GRS, **Cool** or **Archive** blob tier.

2. **“Need high performance for file shares for a line‑of‑business app”**  
   → **Premium FileStorage** account.

3. **“Need Data Lake analytics + folder structure + POSIX ACLs”**  
   → **GPv2 with hierarchical namespace (Data Lake Gen2)** enabled.

4. **“Need to restrict access to one VNet and private IPs only”**  
   → Disable public network access, use **private endpoints**.

5. **“Need to block TLS 1.0/1.1”**  
   → Set **Minimum TLS version** to `TLS1_2`.

6. **“Need accidental delete protection”**  
   → Enable **soft delete** + **versioning** for blobs, **soft delete** for file shares.

If you can comfortably:

- Explain storage account types.
- Pick redundancy and access tiers for a scenario.
- Show how to create/update accounts via Portal/CLI/PowerShell/Bicep.

…then you are in a very good place for this AZ‑104 objective.

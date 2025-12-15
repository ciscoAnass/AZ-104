# Configure Blob Versioning

## A. What is Blob Versioning?

**Blob versioning** automatically keeps **previous versions of a blob** whenever it is modified or deleted.

When versioning is enabled: citeturn2search1turn2search0

- Each blob write or delete creates a new **current version** and moves the previous current version to **previous versions**.
- Each version has a unique **version ID** (a timestamp).
- You can **read** or **restore** any previous version.
- Versions are **immutable** – their content and metadata cannot be changed.

Purpose:

- Recover from **accidental overwrite** (wrong file uploaded).
- Recover from **accidental delete** of a blob.
- Provide **audit/history** of changes for blobs.

> Exam tip: Versioning protects against overwrites/deletes of **individual blobs**, not against deletion of the entire container or storage account.

---

## B. How Blob Versioning Works

### 1. Version Lifecycle

When versioning is **enabled**: citeturn2search1

1. New blob created:
   - A **current version** is created (with version ID).
2. Blob modified (Put Blob, Put Block List, Copy Blob, Set Blob Metadata):
   - The **current version becomes a previous version**.
   - A new version is created as the **current version**.
3. Blob deleted (Delete Blob called without version ID):
   - The **current version becomes a previous version**.
   - There is now **no current version**, but previous versions still exist.

You can still restore by **promoting a previous version** to be current or copying its data.

### 2. Version IDs

- Each version has a **version ID** (timestamp-based).
- Operations without version ID act on the **current version**.
- You can target a specific version by including its **version ID** in API requests.

### 3. Supported Account Types

Blob versioning is available for: citeturn2search1turn2search3

- Standard general-purpose v2 (GPv2).
- Premium block blob accounts.
- Legacy Blob storage accounts.

It is **not** supported on some hierarchical namespace (Data Lake Gen2) scenarios.

### 4. Costs and Performance

Microsoft warns that: citeturn2search1turn2search6

- Every write creates a **new version**, so storage usage grows faster.
- Listing blobs with many versions can increase **latency**.
- Recommended to keep **<1000 versions per blob**.
- Use **lifecycle management** to delete older versions automatically.

---

## C. Enabling and Managing Blob Versioning

### 1. Enable Versioning (Portal)

1. Open the **storage account** in Azure portal.
2. Go to **Data management → Data protection**.
3. Under **Tracking**, enable **Versioning for blobs**.
4. Optionally configure **“Delete versions after X days”** (this adds a lifecycle rule behind the scenes). citeturn2search0turn2search4
5. Save changes.

Versioning applies to **all containers and blobs** in the account.

You can also enable versioning via:

- PowerShell – `Update-AzStorageBlobServiceProperty -IsVersioningEnabled $true`.
- CLI – `az storage account blob-service-properties update --enable-versioning true`. citeturn2search0

### 2. Disable Versioning

You can **disable versioning** later:

- Existing versions **remain**.
- New writes do **not create new versions**; they overwrite the current blob directly. citeturn2search1

Before disabling, you must remove **object replication policies**, because they depend on versioning.

### 3. Listing and Restoring Versions

In the portal: citeturn2search0turn2search4

1. Go to the container and select the blob.
2. Open the **Versions** tab.
3. You can see all versions (optionally also soft-deleted versions).
4. To restore:
   - Either **promote** a version to current, or
   - Download a specific version or copy it over the current version.

Conceptually, restoring means **copying an older version over the current version**.

From CLI/SDKs, you can:

- List versions (with `--include v` or similar flags).
- Get a specific version using its **version ID**.

---

## D. Blob Versioning vs Soft Delete vs Snapshots

### 1. Versioning + Soft Delete

With both **versioning and soft delete** enabled: citeturn2search1turn1search2

- Overwriting a blob:
  - Creates a new version; no soft-deleted snapshot is created.
- Deleting a blob (no version ID):
  - Current version becomes a **previous version**; no soft-deleted snapshot is created.
  - Soft delete retention does **not** affect the main delete operation.
- Deleting a **previous version**:
  - That version is **soft-deleted**, and retained until soft delete retention expires.

So, soft delete mainly protects **versions being deleted**, but your primary safety net from overwrites/deletes is **versioning** itself.

### 2. Versioning vs Snapshots

Both **snapshots** and **versions** keep historical states of a blob, but:

- **Snapshots**:
  - Created **manually** or by apps.
  - Named `blobname@snapshotTime`.
  - Often used before versioning existed.

- **Versions**:
  - Created **automatically** when versioning is enabled.
  - Identified by **version IDs**.
  - Recommended over snapshots for block blobs.

Microsoft recommends: **once versioning is enabled, stop taking manual snapshots for block blobs**, because versioning already captures every update/delete and snapshots just add extra cost. citeturn2search1turn2search4

### 3. Versioning vs Container Soft Delete

- **Blob versioning** – protects individual blobs from modifications and deletes.
- **Container soft delete** – protects against deletion of entire containers (all blobs). citeturn1search0turn2search1

For strong protection, Microsoft recommends enabling:

- Blob versioning.
- Blob soft delete.
- Container soft delete.

---

## E. Lifecycle Management for Versions

Because versions can accumulate quickly, you need a strategy to keep costs under control.

Use **blob lifecycle management** to: citeturn0search7turn0search10turn2search1

- **Delete previous versions** older than X days.
- Move **older versions** to **Cool/Cold/Archive** tiers.

Example rule (conceptual):

- Condition:
  - `daysAfterModificationGreaterThan >= 30`.
- Action:
  - `deletePreviousVersions`.

This keeps up to 30 days of history for each blob.

> Exam tip: If a question mentions **versioning is enabled and storage costs are rising**, the fix is usually **“use lifecycle management to delete older versions”**, not “disable versioning altogether”.

---

## F. Security and Governance Considerations

1. **Permissions**

- Deleting **versions** requires more specific permissions.
- Use Azure RBAC roles like:
  - Storage Blob Data Owner (full control).
  - Storage Blob Data Contributor (read/write, but some delete restrictions for versions may apply depending on version of RBAC model).

2. **Compliance**

- Versioning helps prove **who changed what and when** (with proper logging).
- Combine with **immutability policies** for compliance scenarios where changes must be preserved.

3. **Locks and Account Protection**

- Versioning does **not** protect against deletion of the **storage account** or container.
- Use **resource locks** (`CanNotDelete`) and good RBAC practices to prevent destructive operations. citeturn2search1turn0search30

---

## G. Exam-Style Scenarios

### Scenario 1

> A user overwrote a critical blob in a container by uploading the wrong file. You need to restore the previous content. Blob versioning is enabled. What do you do?

**Answer**:

- In the portal, open the blob → **Versions** tab → **restore/promote** the previous version to current (or copy it over the current version).

### Scenario 2

> Blob versioning is enabled, and you notice that listing blobs in a heavily updated container is slower and your storage bill has increased. What should you configure to reduce cost while retaining 14 days of history?

**Answer**:

- Configure **lifecycle management** to **delete previous versions** older than 14 days.

### Scenario 3

> You must ensure that even if a blob is accidentally deleted, it can be restored, and older versions can also be restored if overwritten. Which features should be enabled?

**Answer**:

- Enable **blob versioning** and **blob soft delete**.

### Scenario 4

> For regulatory reasons, your team wants to keep detailed history of a critical configuration blob, with the ability to roll back any change but without manually creating snapshots. What should you enable?

**Answer**:

- Enable **blob versioning** on the storage account.

---

## H. Quick Summary for the Exam

- Blob versioning = automatic **history of blob changes** (previous versions).
- Each write/delete creates a **new version**; previous current version becomes a **previous version**.
- Versions are **immutable** and identified by **version IDs**.
- Enable versioning via **Data protection** in the storage account.
- Use **lifecycle management** to delete or tier old versions to control cost.
- Combine with **soft delete and container soft delete** for strong data protection.
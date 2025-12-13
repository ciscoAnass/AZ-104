# Configure Soft Delete for Blobs and Containers

## A. Concept: What is Soft Delete?

Soft delete helps protect against **accidental or malicious deletion/overwrite** by keeping deleted data for a **retention period** instead of removing it immediately.

There are two related features in Blob Storage:

1. **Blob soft delete** – protects **individual blobs, snapshots, and versions**.
2. **Container soft delete** – protects **entire containers and their contents**. citeturn1search2turn1search0

During the retention period:

- Deleted items are in a **soft-deleted state**.
- You can **undelete/restore** them.
- You’re **billed** for their storage as if they were active data. citeturn1search2

After the retention period expires:

- Soft-deleted data is **permanently deleted** and cannot be recovered.

> Exam tip: Soft delete is not a full backup solution, but it’s a **critical safety net** for accidental deletes/overwrites.

---

## B. Blob Soft Delete

### 1. What Blob Soft Delete Protects

Blob soft delete protects data deleted or overwritten by:

- **Delete Blob**
- **Put Blob**
- **Put Block List**
- **Copy Blob** operations. citeturn1search2

When soft delete is enabled:

- Deleting a blob keeps a **soft-deleted snapshot** for the retention period.
- Overwriting a blob automatically creates a **soft-deleted snapshot** of the previous state.

### 2. Enabling Blob Soft Delete (Portal Overview)

1. Open the **storage account** in the Azure portal.
2. Go to **Data management → Data protection**.
3. Under **Recovery**, turn on **Soft delete for blobs**.
4. Set **Retention period**: between **1 and 365 days** (Microsoft recommends at least 7 days). citeturn1search5turn0search12
5. Save changes.

You can also enable via:

- **PowerShell** – `Enable-AzStorageBlobDeleteRetentionPolicy`.
- **Azure CLI** – `az storage account blob-service-properties update --enable-delete-retention true --delete-retention-days N`.

New storage accounts created via portal typically have blob soft delete **enabled by default**. citeturn0search12turn1search5

### 3. Restoring a Soft-Deleted Blob

In the portal:

1. Go to **Containers → select container**.
2. Enable **Show deleted blobs** (or similar toggle).
3. Find the deleted blob → choose **Undelete**.

Under the hood, Azure restores the blob to the state it had when it was deleted.

### 4. Pricing Behavior

From Microsoft docs: citeturn1search2turn1search4

- All soft-deleted data is billed at **same rate as active data**.
- You **cannot permanently delete** a soft-deleted blob before retention ends.
- There are advanced workarounds (disable soft delete + undelete + delete), but for the exam, assume: **soft delete keeps items until retention expires**.

---

## C. Container Soft Delete

### 1. What Container Soft Delete Protects

**Container soft delete** protects against **deletion of entire blob containers**. When enabled: citeturn1search0turn1search1

- Deleting a container moves it to a **soft-deleted state** for **1–365 days** (default 7 days).
- During that time, you can restore the container and **all its blobs, snapshots, and versions**.
- After retention, the container is **permanently deleted**.

Important limitations:

- Container soft delete can restore **only whole containers** that were deleted.
- It **does not** restore an individual blob that was deleted while the container was still active (that’s what **blob soft delete/versioning** is for). citeturn1search0

### 2. Enabling Container Soft Delete (Portal Overview)

1. Open the **storage account**.
2. Go to **Data management → Data protection**.
3. Turn on **Soft delete for containers**.
4. Set **Retention days** (1–365, recommended minimum 7).
5. Save.

You can also configure via:

- PowerShell – `Enable-AzStorageContainerDeleteRetentionPolicy`.
- CLI – `az storage account blob-service-properties update --enable-container-delete-retention true --container-delete-retention-days N`. citeturn1search1turn1search8

### 3. Viewing and Restoring Soft-Deleted Containers

Portal flow: citeturn1search1

1. Go to **Containers** in the storage account.
2. Toggle **Show deleted containers**.
3. Select the deleted container → **Undelete**.

The container name must be **free** to restore it. If a new container with the same name was created after deletion, you cannot restore the old one.

### 4. Billing

- Data in soft-deleted containers is **billed at the same rate as active data**. citeturn1search0turn1search4
- Soft-deleted containers are visible only until retention expires.

---

## D. Recommended Data Protection Configuration

Microsoft’s recommended configuration for blob data is: citeturn1search0turn2search1turn1search2

- **Container soft delete** – so you can restore deleted containers.
- **Blob versioning** – to automatically maintain previous versions of blobs.
- **Blob soft delete** – to restore deleted blobs, snapshots, and versions.

Why this matters:

- If a user accidentally deletes a container → container soft delete.
- If a user accidentally overwrites or deletes an individual blob → versioning + blob soft delete.
- If an attacker/script tries to wipe data quickly, you still have a **recovery window**.

> Exam pattern: If the question asks how to **protect against accidental deletion**, and mentions containers vs blobs, you should know which soft delete feature applies.

---

## E. Soft Delete vs Versioning vs Snapshots

### 1. Blob Soft Delete vs Blob Versioning

- **Blob soft delete**:
  - Keeps deleted/overwritten data for a **fixed retention period**.
  - After retention, data is gone.
- **Blob versioning**:
  - Every write creates a **new version** with unique version ID.
  - Older versions persist until manually deleted or removed by lifecycle policy. citeturn2search1turn2search0

When both are enabled:

- Overwrites create **new versions**, not soft-deleted snapshots.
- Deleting a blob makes its **current version** a **previous version** (no current version).
- Deleting a previous version triggers **soft delete** on that version (if enabled), giving you another recovery window. citeturn2search1turn1search2

### 2. Container Soft Delete vs Resource Locks

- **Container soft delete** protects only **container deletion**.
- **Resource locks** (e.g., `CanNotDelete`) on the **storage account** protect against **deletion of the account** (and many management operations).

Exam angle:

- Protect against container deletion → **Container soft delete**.
- Protect against storage account deletion → **Resource lock (CanNotDelete)**.

### 3. Snapshots (Blobs and Files)

- **Blob snapshots** – manual point-in-time copies of a blob.
- **File share snapshots** – for Azure Files (different feature).

When you enable **blob versioning**, Microsoft recommends you **stop taking block blob snapshots** for protection, because versions are enough and snapshots just add cost & complexity. citeturn2search1

---

## F. Exam-Style Scenarios

### Scenario 1

> A developer accidentally overwrote a production blob with the wrong file. Blob soft delete is enabled with 14 days retention. How do you restore the previous data?

**Answer**:

- Use **blob soft delete** / **undelete** functionality in the portal or CLI to restore the blob to its **pre-overwrite state**.

### Scenario 2

> A storage account hosts multiple containers. One entire container was deleted yesterday and needs to be recovered. Which feature must have been enabled beforehand?

**Answer**:

- **Container soft delete**.

### Scenario 3

> You want strong protection for blob data: ability to restore deleted containers, recover accidentally modified blobs, and protect deleted blobs. Which combination should you choose?

**Answer**:

- Enable **container soft delete + blob soft delete + blob versioning**.

### Scenario 4

> A security officer wants to guarantee that even if a malicious admin deletes blobs, they can be recovered for 30 days. What should you configure?

**Answer**:

- Enable **blob soft delete** with **30-day retention**, plus consider **versioning** and **locks** for broader protection.

---

## G. Quick Summary for the Exam

- **Blob soft delete** – protects blobs/snapshots/versions from delete/overwrite for **1–365 days**.
- **Container soft delete** – protects containers from deletion for **1–365 days**.
- Soft-deleted data is **billed like active data** until retention expires.
- Enable both soft delete features and **blob versioning** for best protection.
- Use **resource locks** to protect storage accounts from accidental deletion.

# Manage Data by Using Azure Storage Explorer and AzCopy

## A. Overview

As an Azure administrator, you often need to **move, copy, upload, download, and manage data** in storage accounts.

Two key tools:

1. **Azure Storage Explorer** – graphical (GUI) tool.
2. **AzCopy** – command‑line tool optimized for high‑performance data transfer.

For AZ‑104 you should:

- Know what each tool is for.
- Understand how to authenticate.
- Be able to perform common tasks: upload/download, copy between accounts, and sync.
- Recognize which tool to use in which scenario.

---

## B. Azure Storage Explorer

### 1. What is Storage Explorer?

**Azure Storage Explorer** is a **desktop application** (Windows, macOS, Linux) that lets you:

- Browse and manage:
  - Blob containers and blobs.
  - File shares and files.
  - Queues and messages.
  - Tables (for supported accounts).
- Upload/download data.
- Edit metadata and properties.
- Generate SAS tokens.
- Manage snapshots and soft‑deleted items.

It is ideal for **interactive, manual management** of storage data.

---

### 2. Installing Storage Explorer

- Download the installer from Microsoft’s site.
- Install on your machine (no special prereqs beyond .NET/runtime as required).
- Can also be used in **Azure portal** via a browser‑based version in some contexts (Storage browser), but the exam usually refers to the desktop Storage Explorer.

---

### 3. Authentication methods

When you open Storage Explorer, you can connect to storage using:

1. **Azure account sign‑in (Entra ID)**:
   - Sign in with your user account.
   - You see storage accounts you have access to via Azure RBAC.
   - Recommended for internal/admin scenarios.

2. **Connection string**:
   - Use a full connection string from the portal.
   - Grants access according to the connection string (account keys).
   - Powerful; must be protected.

3. **Shared Access Signature (SAS)**:
   - Use a SAS URL/token for:
     - Blob containers
     - File shares
     - Entire account (account SAS)
   - Grants **limited permissions for limited time**.

4. **Attach using local emulator** (Azurite / older emulator, if used in dev).

**Exam tip**

- If the scenario mentions “use least privilege, do not share account keys” → prefer **role‑based access with Azure AD** or **SAS**.

---

### 4. Common tasks with Storage Explorer

#### a. Browse data

- Expand **Storage Accounts** → your subscription → storage account.
- Choose **Blob Containers**, **File Shares**, **Queues**, or **Tables**.
- Double‑click a container/share to list contents.

#### b. Upload and download

- **Upload**:
  - Right‑click container or folder → **Upload Files** or **Upload Folder**.
  - Choose local files/folder.
- **Download**:
  - Right‑click blob/file → **Download**.
  - Select local target.

Supports:

- Bulk operations.
- Monitoring progress.
- Handling failures and retries.

#### c. Manage containers and file shares

- Create/delete containers and shares.
- Set access level for blob containers (Private, Blob, Container – though public access is now often restricted by policy).
- View and restore **soft‑deleted** blobs or shares (if soft delete is enabled).

#### d. Manage metadata and properties

- View/edit **blob metadata** and **properties**:
  - Content type
  - Caching
  - Custom metadata key/value pairs
- Set **HTTP headers**.

#### e. Generate SAS tokens

- Right‑click on a storage account, container, or blob.
- Choose **Get Shared Access Signature**.
- Configure:
  - Allowed services and resource types.
  - Permissions (read/write/list/delete/add/create/update/process).
  - Start and expiry time.
  - Allowed IP range and protocol (HTTPS only).
- Storage Explorer shows the **SAS connection string** and **SAS URL**.

Useful for:

- Giving temporary access to partners or apps without sharing account keys.

---

## C. AzCopy – command‑line data mover

### 1. What is AzCopy?

**AzCopy v10** is a **command‑line tool** designed for **fast, efficient data transfer** to/from Azure Storage.

- Cross‑platform (Windows, Linux, macOS).
- Single executable: `azcopy`.
- Optimized for:
  - High throughput.
  - Parallel transfers.
  - Large datasets.

Supports:

- **Blob Storage**
- **Azure Files**
- **To/from local disk**
- **Between storage accounts**
- Various protocols and copy scenarios.

---

### 2. Installing and basic usage

1. Download AzCopy v10 from Microsoft.
2. Add it to your **PATH** so you can run `azcopy` from a terminal.

To see help:

```bash
azcopy --help
```

---

### 3. Authentication methods for AzCopy

AzCopy can authenticate in several ways:

1. **Azure AD (Entra ID) sign‑in**

   ```bash
   azcopy login
   ```

   - Opens browser for interactive sign‑in.
   - You use RBAC; no need for account keys or SAS.
   - Good for admins who want to avoid sharing secrets.

2. **Managed identity (from an Azure VM, etc.)**

   ```bash
   azcopy login --identity
   ```

   - Uses system‑assigned or user‑assigned managed identity of the host (VM, container, etc.).
   - Requires proper RBAC assignments on storage.

3. **SAS token (no login needed)**

   - Use full SAS URLs as source and/or destination:
     - `https://account.blob.core.windows.net/container?sas-token`
   - AzCopy doesn’t require `azcopy login` if you use SAS in URL.

4. **Account key / connection string**

   - Less preferred now (too powerful).
   - Often replaced by managed identities and SAS.

**Exam tip**

- “Use AzCopy with least privilege and no account keys” → `azcopy login` with **Azure AD** or `--identity` on a VM with managed identity.

---

## D. AzCopy core command pattern

The main commands you must know:

- **Copy**:

  ```bash
  azcopy copy <source> <destination> [options]
  ```

- **Sync**:

  ```bash
  azcopy sync <source> <destination> [options]
  ```

- **Remove**:

  ```bash
  azcopy remove <destination> [options]
  ```

Common options:

- `--recursive=true` – include subfolders.
- `--from-to=LocalBlob` (or `BlobLocal`, etc.) – to be explicit.
- `--exclude-path`, `--exclude-pattern` – filter what to copy.
- `--overwrite` – control behavior when destination already has files.
- `--dry-run` – show what would happen without actually copying.

---

## E. AzCopy examples – Blob Storage

### 1. Upload local folder to a blob container

Scenario: Upload all files from local folder `C:\data\logs` to container `logs` in storage account `mystorageacc`.

Using SAS on the container:

```bash
azcopy copy "C:\data\logs" "https://mystorageacc.blob.core.windows.net/logs?<SAS_TOKEN>" --recursive=true
```

Notes:

- `--recursive=true` includes subdirectories.
- Use quotes around paths/URLs.

### 2. Download blobs from container to local folder

```bash
azcopy copy "https://mystorageacc.blob.core.windows.net/backups?<SAS_TOKEN>" "C:\backups" --recursive=true
```

This downloads all blobs under `backups` container to `C:\backups`.

### 3. Copy between two storage accounts

Copy container `images` from `sourceacc` to `destacc`:

```bash
azcopy copy \
  "https://sourceacc.blob.core.windows.net/images?<SRC_SAS>" \
  "https://destacc.blob.core.windows.net/images?<DEST_SAS>" \
  --recursive=true
```

Useful for:

- Migrating data to new account/region.
- Duplicating environments.

---

### 4. Sync for one‑way synchronization

`azcopy sync` makes the destination match the source (one‑way).

Example: sync local folder to a container:

```bash
azcopy sync "C:\web-content" "https://mystorageacc.blob.core.windows.net/web?<SAS_TOKEN>" --recursive=true
```

- New or changed local files are uploaded.
- Files that exist in destination but not in source may be deleted (depending on options).
- Good for web content deployments or log uploads.

Example: sync from blob to local:

```bash
azcopy sync "https://mystorageacc.blob.core.windows.net/web?<SAS_TOKEN>" "C:\web-content" --recursive=true
```

---

## F. AzCopy examples – Azure Files

### 1. Upload files to Azure file share

```bash
azcopy copy "C:\files" "https://mystorageacc.file.core.windows.net/myshare?<SAS_TOKEN>" --recursive=true
```

### 2. Download files from file share

```bash
azcopy copy "https://mystorageacc.file.core.windows.net/myshare?<SAS_TOKEN>" "C:\files" --recursive=true
```

### 3. Copy between file share and blob container

```bash
azcopy copy \
  "https://mystorageacc.file.core.windows.net/myshare?<SAS_TOKEN>" \
  "https://anotheracc.blob.core.windows.net/archive?<SAS_TOKEN>" \
  --recursive=true
```

AzCopy understands the service types (Blob, File) from the endpoints.

---

## G. Performance and reliability features in AzCopy

AzCopy is built for big data moves. Key features:

- **Automatic parallelism** – uses multiple concurrent connections to maximize throughput.
- **Resume support** – if a transfer is interrupted, AzCopy can resume where it left off.
- **Logging** – a log file is created by default; you can specify log level, log file location.
- **Job IDs** – each operation has a job ID that you can use to check status or resume.

Useful options:

- `--check-md5` – verify data integrity.
- `--log-level` (e.g., `INFO`, `WARNING`, `ERROR`).
- `--cap-mbps` – cap bandwidth if you don’t want AzCopy to saturate the network.

---

## H. When to use Storage Explorer vs AzCopy

### Azure Storage Explorer (GUI)

Use when:

- You need **ad‑hoc, manual operations**:
  - Quickly view data.
  - Upload/download a few files.
  - Modify metadata.
  - Generate SAS tokens.
- You’re troubleshooting an issue.
- You prefer a **visual** tool.

### AzCopy (CLI)

Use when:

- You need **automation** or scripting (PowerShell, bash, DevOps pipelines).
- You transfer **large amounts of data** (gigabytes/terabytes).
- You want high performance and fine‑grained control:
  - Include/exclude patterns.
  - Sync operations.
  - Batch operations in scripts.

**Exam tip**

- Scenario mentions **“scripted migration of TB of data”** or **“used in CI/CD pipeline”** → **AzCopy**.
- Scenario mentions **“admin wants easy way to visualize containers and generate SAS”** → **Storage Explorer**.

---

## I. Typical exam scenarios

1. **“You must migrate 5 TB of blob data from one subscription to another, with minimal downtime and maximum speed.”**  
   → Use **AzCopy** with SAS or Azure AD login. Script the copy between accounts.

2. **“A support engineer needs to quickly inspect blobs, edit metadata, and restore a soft‑deleted blob without scripting.”**  
   → Use **Azure Storage Explorer**.

3. **“You must regularly synchronize a local folder with a blob container for web content.”**  
   → Use `azcopy sync` from a scheduled task or pipeline.

4. **“You must share access to a container with an external partner for 7 days, read‑only.”**  
   → Use Storage Explorer or portal to create a **SAS URL** with read permission, then share that URL.

If you can:

- Describe what Storage Explorer and AzCopy are.
- Show in your mind how to upload/download and copy between accounts.
- Explain which tool is appropriate for each scenario.

…you are ready for the “Manage data by using Azure Storage Explorer and AzCopy” objective in AZ‑104.

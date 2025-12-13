# Create and Configure a Container in Azure Blob Storage

## A. Blob Storage Basics

### What is a Container?

In Azure Blob Storage, the hierarchy is:

- **Storage account**
  - **Container**
    - **Blobs** (files/objects)

A **container** is like a top-level folder that groups blobs together. You cannot store blobs directly in a storage account; they must always be inside a container.

Common use cases:

- Store application logs, images, videos, backups.
- Host static website content (via special `$web` container).
- Archive data at low cost (Archive tier).

### Blob Types (Quick Reminder)

- **Block blobs** – most common (files, images, backups, logs).
- **Append blobs** – optimized for append operations (log files).
- **Page blobs** – used for Azure disks (random read/write).

Most exam questions on containers assume **block blobs**.

---

## B. Container Naming and Structure

### Naming Rules

Container names:

- Must be **lowercase**.
- 3–63 characters.
- Can contain only letters, numbers, and `-` (hyphen).
- Must start and end with a letter or number.
- No consecutive hyphens (`--`) at start/end patterns that cause issues in DNS.

Examples:

- ✅ `images`
- ✅ `prod-backups`
- ❌ `ProdBackups` (uppercase not allowed)
- ❌ `-logs` (cannot start with `-`)

> Exam tip: If the question shows a container name with uppercase characters → it’s **invalid**.

### Logical Structure

Inside a container, you can simulate folders by using `/` in blob names:

- Blob name: `app1/logs/2025/11/16/app.log`
- There are no true “folders”; it’s a **flat namespace** with virtual directories.

---

## C. Creating a Container (Portal High-Level)

1. In the **Azure portal**, open your **storage account**.
2. Under **Data storage**, select **Containers**.
3. Click **+ Container**.
4. Configure:

   - **Name** – per rules above.
   - **Public access level**:
     - **Private (no anonymous access)** – **recommended default**.
     - **Blob** – anonymous read access to **blobs only**.
     - **Container** – anonymous read access to **container & blob list**.
   - (Optional) **Advanced** options depending on portal view.

5. Click **Create**.

You can also create containers via:

- CLI: `az storage container create`
- PowerShell: `New-AzStorageContainer`
- SDKs in .NET, Python, Java, etc.

---

## D. Container Access and Security

### 1. Public Access Levels

Azure Storage supports **optional anonymous read access**. By default, **anonymous access is disabled** – all requests must be authorized. citeturn0search18turn0search30

Public access levels:

1. **Private (Off)** – No anonymous access; all requests must be authenticated.
2. **Blob (Container-level public access: blobs only)** –
   - Anyone with blob URL can **read** blob content and metadata.
   - Cannot list container contents anonymously.
3. **Container (Container-level public access: container & blobs)** –
   - Anyone can list blobs in container & read them.
   - Strongly discouraged for sensitive data.

Best practice & exam answer:

- Disable anonymous public access wherever possible.
- If a business requirement needs public images/files, use **limited containers** with just that data.

> There is also **account-level setting** to completely disable public blob access so that even containers set to “Public” cannot expose data.

### 2. Authorization Methods

Clients can access containers/blobs using:

1. **Azure AD / Microsoft Entra ID**  
   - Use **RBAC** roles like:
     - Storage Blob Data Reader
     - Storage Blob Data Contributor
     - Storage Blob Data Owner
   - Best for users & applications (managed identities).

2. **Shared Key (account key)**  
   - Full access to the account (not least privilege).
   - Suitable for admin scripts, but risky for broad use.

3. **Shared Access Signatures (SAS)**  
   - Delegated, time-limited access.
   - Types:
     - **Service SAS** (signed with account key).
     - **User delegation SAS** (signed with Azure AD token – more secure).
   - Scope to one container or even down to one blob.

4. **Anonymous access**  
   - Only if public access is enabled as described above.

> Exam tip: If the question emphasizes **“least privilege”** and avoiding account keys, answer with **Azure AD (RBAC)** or **user delegation SAS**.

### 3. Encryption and Data Protection

By default, Azure Storage:

- Encrypts data **at rest** with Microsoft-managed keys.
- You can configure **customer-managed keys (CMK)** stored in **Key Vault** for compliance.

At storage account / container level you can also use additional protection:

- **Immutability policies (WORM)** – time-based retention or legal hold. citeturn0search2turn0search21turn0search23
- **Soft delete, blob versioning, container soft delete** – described in other notes but strongly tied to containers.

---

## E. Important Container-Level Features

### 1. Immutability (WORM) Policies

You can configure a container with a **WORM (Write Once, Read Many)** policy:

- **Time-based retention**:
  - Example: retain data for 7 years.
  - During retention, blobs cannot be modified or deleted.
- **Legal hold**:
  - Retention not fixed; data is immutable until legal hold is explicitly cleared. citeturn0search2turn0search23

Use cases:

- Financial audit data.
- Logs for regulatory investigations.
- Compliance with regulations (e.g., SEC, GDPR aspects).

### 2. Data Protection Settings

The **storage account’s Data protection** blade controls behavior applied to containers & blobs:

- **Container soft delete** – restore deleted containers within retention. citeturn1search0turn1search1
- **Blob soft delete** – restore deleted/overwritten blobs.
- **Blob versioning** – keep previous versions automatically.
- **Change feed** – append-only log of blob creations, updates, deletes.

You can’t enable these *on a single container only*; they are mostly **account-wide** settings that affect all containers.

> Recommended configuration from Microsoft: enable **container soft delete + blob versioning + blob soft delete** for maximum protection. citeturn1search0turn2search1

### 3. Static Website Hosting

If you enable **Static website** on a storage account:

- Azure creates a special container named `$web`.
- Upload your HTML/CSS/JS files to `$web`.
- Static website endpoint (for example):  
  `https://<storage-account>.z13.web.core.windows.net`

Exam angle:

- If they ask for **simple static website hosting** with cheapest option, no server-side code → **Storage account static website** is the answer, not App Service.

---

## F. Managing a Container

### 1. Container Properties

In the portal, on a specific container, you can view/configure:

- **Public access level** (change between Private / Blob / Container).
- **Access policy** (stored access policies for SAS).
- **Immutability policy & legal holds** (if enabled).
- **Container-level metrics** (if diagnostics configured).

### 2. Stored Access Policies

Instead of generating SAS tokens directly with expiry & permissions, you can use **stored access policies**:

- Define a policy on the container (start time, expiry, permissions).
- Create SAS tokens that reference this policy ID.

Advantages:

- Central control: revoke or change the policy → all SAS tokens using it change behavior automatically.
- Useful for long-lived SAS or external partners.

### 3. Monitoring and Logging

Use **Azure Monitor / diagnostic settings** to:

- Send storage logs to **Log Analytics**, **Event Hubs**, or another storage account.
- Track operations like `GetBlob`, `PutBlob`, `DeleteContainer`.
- Build alerts on access patterns, failures, etc.

Best practice: enable logging in production, especially for security-sensitive containers.

---

## G. Security & Best Practices (Exam Focus)

1. **Default to private containers** – only authorized clients get access.
2. **Prefer Azure AD & RBAC** over shared keys.
3. **Disable public access at the account level** if not needed at all.
4. Use **immutability** for compliance workloads.
5. Enable **soft delete + versioning + container soft delete** for important data.
6. Protect the storage account itself with:
   - Resource locks (`CanNotDelete`).
   - Resource group/subscription RBAC.
   - Network restrictions & private endpoints.

---

## H. Exam-Style Scenarios

### Scenario 1

> You need to expose product images publicly over the internet, but no other data should be public. What do you configure?

**Answer reasoning**:

- Create a **dedicated container** (e.g., `product-images`) in a storage account.
- Set **public access level** to **Blob**.
- Keep other containers **private** or disable anonymous access at account level and use CDN/SAS if needed.

### Scenario 2

> A finance department must store invoices for 7 years in a WORM state. Data must not be deletable or modifiable during this time. What should you configure?

**Answer**:

- Enable **immutability (time-based retention)** on the **container** holding invoices.

### Scenario 3

> A developer accidentally deleted a blob container yesterday. You must restore it. Which feature helps?

**Answer**:

- **Container soft delete** (must have been enabled before deletion).

---

## I. Quick Summary for the Exam

- A **container** is the top-level logical grouping for blobs inside a storage account.
- Container names: lowercase, 3–63 chars, letters/numbers/hyphens.
- Public access levels: **Private / Blob / Container**; default is **private**.
- For secure access: **Azure AD + RBAC**, SAS, private endpoints, and disabled public access.
- Use **immutability policies** for WORM compliance.
- Use **container soft delete + blob versioning + blob soft delete** for strong data protection.
- Special `$web` container is used for static website hosting.
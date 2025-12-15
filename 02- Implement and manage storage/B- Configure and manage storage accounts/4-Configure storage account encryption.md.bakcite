
# Configure Storage Account Encryption

## A. Why encryption matters

Azure Storage automatically encrypts data **at rest** to protect it from unauthorized access if someone gains physical access to disks or infrastructure.

As an Azure administrator (AZ‑104), you must:

- Understand how **encryption at rest** works in Azure Storage.
- Choose between **Microsoft‑managed keys** and **customer‑managed keys (CMK)**.
- Know when to use **encryption scopes** and **customer‑provided keys**.
- Configure **transport encryption** (TLS and secure transfer).

---

## B. Storage Service Encryption (SSE) – basics

**Storage Service Encryption (SSE)** is built into Azure Storage.

Key points:

- All data written to Azure Storage is **automatically encrypted** before being persisted.
- Data is decrypted **transparently** when read – clients don’t need to manage decryption logic.
- Uses strong symmetric encryption (AES‑256).
- **Cannot be disabled** for modern storage accounts.

This covers:

- Blobs (including Data Lake Gen2)
- Azure Files shares
- Tables
- Queues
- Snapshots and copies

You manage **which keys** are used for encryption:

1. **Microsoft‑managed keys** (default)
2. **Customer‑managed keys (CMK)** stored in Key Vault or Managed HSM
3. **Customer‑provided keys (CPK)** per request (advanced scenario)

---

## C. Microsoft‑managed keys (default)

By default, a storage account uses **Microsoft‑managed keys**:

- Keys are created, rotated, and managed by **Microsoft**.
- Stored in Microsoft‑controlled HSMs in Azure.
- You do not see or handle the keys.
- Satisfies many basic security and compliance requirements.

Configuration:

- “Microsoft‑managed keys” is selected in the **Encryption** section when creating or editing a storage account.
- No extra configuration needed.

When is this enough?

- For many internal workloads and non‑regulated applications.
- When your org does not require full control over encryption keys.

---

## D. Customer‑managed keys (CMK)

If your organization requires **control over the keys** (for example, for regulatory standards or key‑rotation policies), use **CMK**.

### 1. Where CMKs are stored

You store CMKs in:

- **Azure Key Vault**, or
- **Azure Key Vault Managed HSM**.

The storage account uses a **key URI** from Key Vault / HSM to encrypt data encryption keys.

### 2. How CMK integration works

High‑level flow:

1. You create or identify a **Key Vault** / Managed HSM in the same region (commonly) and tenant.
2. You create a **key** (RSA or symmetric, depending on scenario) in Key Vault.
3. You allow the storage account to access that key by:
   - Enabling **managed identity** on the storage account (system‑assigned or user‑assigned).
   - Granting that identity permissions on the key:
     - Typically `get`, `wrapKey`, `unwrapKey` (and maybe `list`).
4. In the storage account **Encryption** settings:
   - Choose **Customer‑managed key**.
   - Select the Key Vault and key.
   - Optionally configure **key rotation**.

The key in Key Vault is used to **protect the data encryption keys** that actually encrypt the data (envelope encryption pattern).

### 3. Benefits of CMK

- You can control **key lifecycle**:
  - Manual or automatic rotation.
  - Soft delete and recovery.
- You can control who is allowed to encrypt/decrypt via **Key Vault RBAC**.
- Helps meet standards like:
  - ISO/IEC 27001, SOC, PCI‑DSS, HIPAA, etc. (depending on your configuration and region).

### 4. Risks and considerations

- If the key becomes **unavailable** (deleted, disabled, access revoked), the storage account may not be able to **decrypt data** → downtime.
- You must monitor key health and storage account **encryption status**.
- Extra costs for Key Vault operations and Managed HSM.

**Exam tip**

- If the requirement says **“customer‑managed key”**, **“bring your own key (BYOK)”**, or **“control key rotation in Key Vault”**, you must choose CMK.

---

## E. Configuring CMK in the Azure portal

### Step 1 – Create / choose a Key Vault

1. Create a **Key Vault** in the same region as your storage account (recommended).
2. Add a key:
   - Go to **Objects → Keys → Generate/Import**.
   - Choose key type and size (e.g., RSA‑2048).

### Step 2 – Enable managed identity on storage account

1. Go to the **storage account** → **Identity** (System‑assigned).
2. Turn status to **On** → **Save**.
3. This creates a **managed identity** representing the storage account.

### Step 3 – Grant Key Vault access

1. In **Key Vault**:
   - Use **Access policies** or **RBAC** (depending on your Key Vault configuration).
2. Grant the storage account’s managed identity:
   - `Get`
   - `Wrap Key`
   - `Unwrap Key`
   - (and optionally `List`)

### Step 4 – Configure encryption

1. In the **storage account**, go to **Encryption** blade.
2. Select **Customer‑managed keys**.
3. Select **Key vault** and then choose the key.
4. Confirm and **Save**.

The storage account now uses the CMK to encrypt new data. Existing data is gradually re‑encrypted (implementation details are internal to Azure).

---

## F. Encryption scopes

**Encryption scopes** allow you to apply different encryption settings to **different containers or blobs** within the same storage account.

Why use them?

- Need **some containers with CMK** (highly sensitive data), and others with **Microsoft‑managed keys** (less sensitive) in the same account.
- Need to apply different CMKs to different datasets.

Key points:

- You define one or more **encryption scopes** in the account.
- Each scope can specify:
  - Use Microsoft‑managed key, or
  - Use CMK from Key Vault / HSM.
- You can then assign an encryption scope to:
  - A blob container (default for all blobs in that container).
  - Individual blobs (if needed).

Configuration (high level):

- Portal → Storage account → **Encryption scopes**:
  - Add a new scope.
  - Choose key source (Microsoft‑managed or CMK).
  - For CMK, provide Key Vault and key.
- When creating a container or blob, specify the **encryption scope**.

On the exam, you don’t need every implementation detail, but you must know:

- Encryption scopes let you **mix key types** within one account.
- Useful for **regulatory separation** of different data sets.

---

## G. Customer‑provided keys (CPK)

**Customer‑provided keys** are for scenarios where the client supplies the encryption key **with each request**.

Two flavors:

1. **CPK with client‑provided key**:
   - Client sends the key directly in the request header.
   - Azure Storage uses it only for that operation.
2. **CPK with Key Vault‑stored key** (client provides key reference and obtains key at runtime).

Use cases:

- Strict policies where the cloud provider **must never store or manage the key**.
- Specialized applications that have their own key management.

CPK is **advanced** and not as common as CMK. For AZ‑104, you mainly need to:

- Know that it exists.
- Understand that the app must manage and provide keys **on every request**.
- It is not configured on the account; it’s used per request in client libraries.

---

## H. Transport security – secure transfer and TLS

Encryption at rest is **only half the story**. You also need to secure data **in transit**.

### 1. Secure transfer required

Property: **“Secure transfer required”** (sometimes called HTTPS‑only).

- When enabled:
  - Blob/Table/Queue endpoints **only accept HTTPS**.
  - HTTP requests are rejected.
  - For Azure Files:
    - Requires SMB 3.0 with encryption when using public endpoints.

Set this when:

- You want to ensure no unencrypted HTTP access is allowed.
- You must meet security standards requiring encrypted transport.

### 2. Minimum TLS version

You can configure a **minimum TLS version** that clients must use:

- Options:
  - `TLS1_0`
  - `TLS1_1`
  - `TLS1_2`
- Azure Storage supports TLS 1.2 and 1.3 on public endpoints, but you can’t currently enforce 1.3 as minimum; typical recommendation is **TLS 1.2**.
- Clients using older TLS versions will fail to connect when minimum is higher.

Exam pattern:

- “Security team wants to block TLS 1.0 and 1.1” → set **minimum TLS version = TLS 1.2**.
- “Force HTTPS” → enable **secure transfer required**.

Configuration:

- Portal → Storage account → **Configuration**:
  - Secure transfer required: **Enabled**.
  - Minimum TLS version: select **TLS 1.2**.
- CLI:

  ```bash
  az storage account update \
    --name mystorageacc \
    --resource-group rg1 \
    --https-only true \
    --min-tls-version TLS1_2
  ```

---

## I. Infrastructure encryption (double encryption)

Some regions and account types support **infrastructure encryption (double encryption)**:

- Data is encrypted **twice** using two independent encryption layers:
  - One at the storage service level (SSE).
  - Another at the infrastructure level (underlying disk).
- Purpose: extra protection for compliance and defense‑in‑depth.

Configurable typically when creating the storage account:

- Portal → **Encryption** → enable **Infrastructure encryption**.
- Once enabled, cannot usually be disabled.

For AZ‑104, know:

- “Double encryption” or “infrastructure encryption” = enable this feature.
- It adds overhead and cost but improves security posture.

---

## J. Example configurations (Portal and CLI)

### 1. Switch from Microsoft‑managed keys to CMK (Portal)

1. Create Key Vault and key.
2. Enable system‑assigned managed identity on the storage account.
3. Grant Key Vault access to that identity.
4. Storage account → **Encryption**:
   - **Customer‑managed key**
   - Select Key Vault and key.
   - Save.

### 2. Configure CMK via CLI (outline)

```bash
# Variables
RG="rg-az104-lab"
ACC="az104storagexyz"
KV_RG="rg-keyvault"
KV_NAME="kv-encryption"
KEY_NAME="storage-key"

# 1. Enable managed identity on the storage account
az storage account update \
  --name $ACC \
  --resource-group $RG \
  --assign-identity

# Get the principal ID for the managed identity
identity_principal_id = !az storage account show --name $ACC --resource-group $RG --query "identity.principalId" -o tsv
```

(For the exam, you don’t need to memorize the exact CLI for assigning Key Vault access. It is enough to know the steps: assign identity → give Key Vault permissions → point storage account to Key Vault key.)

---

## K. Exam tips and patterns

1. **“Data must be encrypted at rest using customer‑managed keys stored in Azure Key Vault; security team controls key rotation.”**  
   → **Customer‑managed keys (CMK)** with Key Vault and managed identity.

2. **“We must ensure no unencrypted network traffic to the storage account, and TLS 1.0/1.1 are not allowed.”**  
   → Enable **secure transfer required** and set **minimum TLS version 1.2**.

3. **“Some containers hold highly sensitive data and must use a separate CMK; others can use Microsoft‑managed keys.”**  
   → Use **encryption scopes** with different key sources.

4. **“Compliance requires that the cloud provider not store our encryption keys; app must supply keys directly.”**  
   → Use **customer‑provided keys (CPK)** (advanced).

5. **“Need extra layer of encryption for highly regulated environment.”**  
   → Enable **infrastructure (double) encryption** where available.

If you can:

- Explain SSE, CMK, CPK, and encryption scopes.
- Configure CMK with Key Vault and managed identity.
- Configure transport security (HTTPS and TLS).

…you are ready for the encryption part of AZ‑104.


# Configure Azure Disk Encryption (ADE) and Other Disk Encryption Options

## A. Why Disk Encryption Matters

Disk encryption helps protect data at rest if:

- Someone gets a copy of your disk (for example from a backup or snapshot).
- A disk is stolen from a datacenter (physical risk).
- You must meet compliance rules (regulations that *require* encryption).

In Azure, there are several layers of encryption. For the AZ‑104 exam, you must understand the differences and when to use each option.

---

## B. Encryption Options for Azure VM Disks

### 1. Storage Service Encryption (SSE)

- **What it is:** Server‑side encryption performed automatically by Azure Storage on managed disks, snapshots, and images.
- **Default behavior:** All managed disks are encrypted at rest by default using **platform‑managed keys** (PMK).
- **No agent required inside the VM.**
- **Performance impact:** Designed to be negligible for typical workloads.

You can choose between:

1. **Service-managed keys (PMK)**
   - Azure manages keys for you.
   - Simplest option; default for most disks.
2. **Customer-managed keys (CMK)**
   - You store the encryption keys in **Azure Key Vault**.
   - Gives more control (key rotation, disabling, auditing).
   - Used when strict compliance requires that *you* control the keys.

### 2. Azure Disk Encryption (ADE)

**Azure Disk Encryption** is **guest‑based** encryption:

- Uses **BitLocker** (Windows) or **dm‑crypt** (Linux) inside the OS.
- Encrypts OS and data volumes from inside the VM.
- Works together with **Azure Key Vault** for key storage.
- Often used for:
  - “Double encryption” (OS‑level + SSE).
  - Special compliance requirements where full volume encryption with specific algorithms is required.

Key ideas:

- ADE uses a **Disk Encryption Key (DEK)** to encrypt the volume.
- DEK itself can be wrapped by a **Key Encryption Key (KEK)** stored in Key Vault.
- ADE requires a **supported OS** and VM configuration.

### 3. Encryption at host

Another option (often seen in exam questions) is **encryption at host**:

- Encrypts data on the physical host before writing to the storage backend.
- Protects OS disks, data disks, and temp disks.
- Uses keys (PMK or CMK) similar to SSE but applied at host level.
- Enabled at the VM or scale set level.

### 4. Ephemeral OS disks

- Ephemeral OS disks keep the OS on **local host storage**.
- They **cannot** be encrypted with Azure Disk Encryption or backed up.
- They are suitable for **stateless** workloads; data should not rely on this disk.

Exam tip: If the question mentions “stateless VM, very fast provisioning, no need to preserve OS changes” → likely using **ephemeral OS disk**, and Azure Disk Encryption is **not** applicable.

---

## C. When to Use Which Option

| Scenario | Recommended Option |
|---------|--------------------|
| General workloads, default security | SSE with service‑managed keys (default). |
| Compliance requires customer‑controlled keys | SSE with CMK (Key Vault). |
| Need disk encryption inside guest OS (BitLocker/dm‑crypt), double encryption, or specific OS‑level controls | Azure Disk Encryption (ADE) with Key Vault. |
| Need encryption for temp disk, cache, and data on host | Encryption at host (plus SSE). |
| Stateless workloads, very fast, no persistent OS | Ephemeral OS disks (no ADE, rely on host security & app‑level resiliency). |

Exam trick: Many questions try to confuse SSE, ADE, and encryption at host. Remember:
- ADE = **inside OS**, uses BitLocker/dm‑crypt + Key Vault.
- SSE = **storage layer**, automatic, no guest agent.
- Encryption at host = **hypervisor level** encryption for disks and temp storage.

---

## D. Prerequisites for Azure Disk Encryption

To use **Azure Disk Encryption (ADE)** you typically need:

1. **Supported VM and OS**
   - Check that the OS image supports BitLocker or dm‑crypt.
   - Some SKUs or ephemeral OS disks are not supported.

2. **Azure Key Vault**
   - Must be in the **same region and subscription** as the VM disks.
   - Soft delete and purge protection should be enabled (recommended/best practice).
   - Access policies or RBAC permissions allow the VM’s identity to:
     - Get/wrap/unwrap keys if using KEK.
     - Write secrets if using KEK/DEK patterns.

3. **Identity for the VM**
   - System‑assigned or user‑assigned **managed identity** is recommended.
   - The identity must have the required Key Vault privileges.

4. **Network connectivity**
   - Key Vault must be reachable from the VM (consider private endpoints, NSGs, firewalls).

Exam tip: If you see “central security team must manage encryption keys in a dedicated Key Vault, keys must be rotated regularly” → think **Customer‑managed keys** and managed identity + Key Vault.

---

## E. Configure SSE with Customer‑Managed Keys (CMK)

This option encrypts managed disks at the storage level with your own keys.

### High‑Level Steps (Portal)

1. **Create Key Vault**
   - In the same subscription and region as the disks.
   - Enable soft delete and purge protection.
   - Create or import a key (for example `kv-disk-key-01`).

2. **Grant disk encryption identity access**
   - Either create a dedicated **disk encryption set (DES)** (recommended) or use the disk resource directly where supported.
   - The DES has an identity in Entra ID.
   - In Key Vault, grant DES identity `get`, `wrapKey`, `unwrapKey` permissions (or Key Vault RBAC equivalent).

3. **Create or update the disk**
   - When creating a managed disk or VM, choose **customer-managed keys** and select the DES / Key Vault key.
   - For existing disks, you can switch from PMK to CMK, subject to limitations.

4. **Apply to VM OS and data disks**
   - After enabling at disk level, the VM’s OS and data disks use CMK at rest.

### Azure CLI example (simplified)

```bash
# 1. Create a disk encryption set
az disk-encryption-set create \
  --name des-vm-os \
  --resource-group rg-az104-compute \
  --key-url https://mykeyvault.vault.azure.net/keys/disk-key-01/<key-version> \
  --source-vault mykeyvault

# 2. Grant the DES identity access in Key Vault (via portal or CLI)

# 3. Create managed disk using the DES
az disk create \
  --name osdisk-cmk \
  --resource-group rg-az104-compute \
  --size-gb 128 \
  --encryption-type EncryptionAtRestWithCustomerKey \
  --disk-encryption-set des-vm-os
```

For the exam, you do not need to memorize every parameter, but you should know the **concept**:

- CMK → Key Vault key → Disk Encryption Set → linked to managed disks.

---

## F. Configure Azure Disk Encryption (ADE) on a VM

### 1. Portal (Windows VM example)

High‑level steps:

1. Ensure you have a **Key Vault** with a key and appropriate access policies.
2. Open the **VM → Disks → Encryption** blade.
3. Choose **Azure Disk Encryption** for OS and data disks.
4. Select:
   - Key Vault.
   - Encryption key (or let Azure generate one).
   - Optionally, a KEK key for wrapping the DEK.
5. Start **encryption**. ADE installs/uses the extension inside the VM.

After enabling ADE:

- ADE extension manages BitLocker (Windows) or dm‑crypt (Linux).
- OS and data volumes are encrypted from inside the guest.
- You can view encryption status in the VM blade and Key Vault.

### 2. Azure CLI Example (Linux)

```bash
# Enable ADE on a Linux VM with managed identity

az vm encryption enable \
  --name vm-linux-web01 \
  --resource-group rg-az104-compute \
  --disk-encryption-keyvault mykeyvault \
  --key-encryption-key my-ade-key \
  --key-encryption-keyvault mykeyvault
```

Typical parameters:

- `--disk-encryption-keyvault` – Key Vault that stores disk encryption secrets.
- `--key-encryption-key` – Name of KEK (optional).
- `--key-encryption-keyvault` – Key Vault that stores KEK.

### 3. Check Encryption Status

```bash
az vm encryption show \
  --name vm-linux-web01 \
  --resource-group rg-az104-compute \
  --query [osDisk,status]
```

In the portal, you can also check **VM → Disks → Encryption**.

---

## G. Special Cases and Limitations

Some situations require extra care when using ADE or CMK:

1. **Moving encrypted VMs between resource groups or subscriptions**
   - There are documented **limitations** and **workarounds**.
   - Sometimes you must temporarily disable backup or ADE, or recreate from snapshots.
   - For the exam, remember that *moving encrypted VMs may require extra steps*.

2. **Backup and Site Recovery**
   - Azure Backup and Site Recovery support encrypted VMs with some requirements (Key Vault access, supported regions, etc.).
   - For ADE‑encrypted VMs, Backup must have access to Key Vault.

3. **Marketplace images with plans**
   - Some Marketplace images require special handling when moving between subscriptions or using ADE.

4. **Ephemeral OS disks**
   - ADE and backup do not apply.
   - Use application‑level redundancy and stateless design.

5. **Performance considerations**
   - SSE and Encryption at host are optimized to have minimal performance impact.
   - ADE adds encryption work inside the OS; normally acceptable but test accordingly in performance‑critical workloads.

Exam tip: If a scenario is about **simple at‑rest encryption** and the question never mentions BitLocker, dm‑crypt, or double encryption → SSE with PMK/CMK is usually enough; ADE is more complex and rarely the default answer.

---

## H. Best Practices

1. **Prefer SSE with CMK for compliance**  
   - Easier to manage than ADE.
   - Use Disk Encryption Sets and Key Vault RBAC.

2. **Use ADE only when required**
   - When regulations or internal policy mandate OS‑level disk encryption with specific algorithms or key handling.

3. **Use managed identities**
   - Avoid storing secrets; grant Key Vault access to managed identities instead of service principals with passwords.

4. **Secure Key Vault**
   - Enable soft delete and purge protection.
   - Restrict network access using private endpoints or firewall rules.
   - Use RBAC or access policies carefully (least privilege).

5. **Automate**
   - Use ARM/Bicep or CLI/PowerShell scripts to enforce consistent encryption.
   - Combine with **Azure Policy** to audit/deny unencrypted disks.

6. **Monitoring and alerting**
   - Send metrics and logs for encryption operations to Log Analytics.
   - Create alerts if encryption is disabled or keys are near expiry.

---

## I. Exam Summary

- **All managed disks are encrypted at rest by default with SSE.**
- You can switch from service‑managed keys to **customer‑managed keys** using Key Vault and Disk Encryption Sets.
- **Azure Disk Encryption (ADE)** is guest‑based encryption using BitLocker (Windows) or dm‑crypt (Linux) and needs Key Vault + identity.
- **Encryption at host** encrypts data on the physical host before writing to storage.
- Ephemeral OS disks are **not compatible** with ADE and Backup; used for stateless, high‑performance workloads.
- Moving or backing up encrypted VMs sometimes requires **special steps**; always consider Key Vault access and supported scenarios.

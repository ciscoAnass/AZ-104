# Configure Access to Storage – Introduction

## A. Where this fits in AZ-104

This folder covers the **“Configure access to storage”** part of the AZ-104 exam, inside:

> Implement and manage storage (15–20%) → Configure access to storage

In practice, **“access to storage”** means answering three big questions for any Storage account:

1. **Who** can access the data?  
   - Using **keys**, **SAS tokens**, or **identity-based access** (Microsoft Entra ID).
2. **From where** can they access it?  
   - Using **firewalls**, **IP rules**, **virtual networks**, or **private endpoints**.
3. **With which permissions and for how long?**  
   - Using **SAS scopes**, **stored access policies**, and **RBAC roles**.

The AZ-104 exam expects you to be able to **design**, **configure**, and **troubleshoot** these mechanisms.

This folder is divided into 5 detailed files:

1. **Configure Azure Storage firewalls and virtual networks**  
   - Control network access to Storage accounts (IP rules, VNets, resource instance rules, trusted services). citeturn0search0turn0search5
2. **Create and use shared access signature (SAS) tokens**  
   - Grant fine-grained, time-limited access to specific resources, without sharing account keys. citeturn0search1turn0search16
3. **Configure stored access policies**  
   - Centralize SAS management, support bulk revocation, and define SAS lifetime and permissions at the container/share/queue/table level. citeturn0search2turn0search7
4. **Manage access keys**  
   - Understand what account keys do, how to rotate them, and why you should prefer SAS or Entra-based access when possible. citeturn0search3turn0search29
5. **Configure identity-based access for Azure Files**  
   - Use Microsoft Entra ID and RBAC instead of keys, especially for SMB access to Azure file shares. citeturn0search4turn0search9turn0search30

---

## B. Big picture: Layers of protection

When securing Azure Storage, think in **layers**:

1. **Identity & Authorization (WHO)**  
   - **Account keys** – full control of the storage account (data plane).  
   - **SAS tokens** – scoped, time-limited delegation of access.  
   - **Microsoft Entra ID / RBAC** – identity-based access, especially for Azure Files and Blob (user delegation SAS). citeturn0search1turn0search6

2. **Network access (FROM WHERE)**  
   - **Public endpoint – all networks** (default): open to internet (with authentication).  
   - **Public endpoint – selected networks**: only allowed IP ranges, VNets, and resource instances can reach the endpoint. citeturn0search5turn0search10  
   - **Private endpoint (Private Link)**: a private IP inside your VNet; traffic stays on the Microsoft backbone.  
   - **Trusted Azure services**, **IP rules**, **virtual network rules**, **resource instance rules** add more granularity. citeturn0search0turn0search17

3. **Data protection (WHAT HAPPENS TO DATA)**  
   - Encryption at rest (service-managed or customer-managed keys).  
   - Redundancy (LRS/ZRS/GRS/GZRS) and soft delete / versioning.  
   - These belong to other sections, but you should remember them when designing storage security overall.

### Simple layered model

```text
[User or App]
     |
     v
[Identity & Permission]  -->  SAS / Keys / Entra ID / RBAC
     |
     v
[Network Access]         -->  Firewall, IP, VNet, Private Endpoint
     |
     v
[Data Plane Operations]  -->  Read / Write / List / Delete blobs, files, queues, tables
```

If **any** layer denies the request, access fails.

---

## C. How the 5 files connect together

These 5 files are designed as a **mini-course**. You can study them in order, or jump to the one you need.

### 1. Firewalls and virtual networks

You’ll learn:

- Default network behavior of Storage accounts. citeturn0search5turn0search10  
- How to switch from “All networks” to “Selected networks”.  
- IP rules, VNet rules, resource instance rules, trusted Azure services. citeturn0search0turn0search17  
- Typical exam scenarios like:
  - “Allow only traffic from a specific subnet.”  
  - “Block access from the internet but allow Azure Functions to reach storage.”

### 2. SAS tokens

You’ll learn:

- What SAS is and why it’s better than giving out account keys. citeturn0search1turn0search21  
- Types of SAS:
  - **User delegation SAS** (Entra-based, for Blob only). citeturn0search6turn0search11  
  - **Service SAS** (per-service resource like a blob or file).  
  - **Account SAS** (multiple services at once).  
- Structure of a SAS URL and which fields matter for the exam (permissions, expiry, IP range, protocol). citeturn0search16turn0search24  
- Real-world examples and how to decide which type to use.

### 3. Stored access policies

You’ll learn:

- What a stored access policy is and how it links to SAS. citeturn0search2turn0search7turn0search12  
- Why policies are better than ad-hoc SAS for long-lived scenarios (revocation, rotation).  
- Limits (max 5 policies per container/share/queue/table). citeturn0search2turn0search7  
- How to revoke or update many SAS tokens at once by changing a single policy.

### 4. Manage access keys

You’ll learn:

- What account keys really are (root data-plane secret for the account). citeturn0search3  
- Why Microsoft recommends **not** giving keys to apps or users when SAS or Entra auth is possible. citeturn0search3turn0search21  
- Key rotation strategies:
  - Using **key1** while regenerating **key2**, then switch and repeat. citeturn0search3turn0search18turn0search26  
  - Using **Azure Key Vault** to store and auto-rotate keys. citeturn0search3turn0search8turn0search13

### 5. Identity-based access for Azure Files

You’ll learn:

- High-level architecture of Azure Files with identity-based authentication (SMB with Kerberos + Entra). citeturn0search9turn0search14turn0search30  
- Share-level permissions using Azure RBAC roles like:
  - **Storage File Data SMB Share Reader / Contributor / Elevated Contributor / Privileged Contributor / Privileged Reader**. citeturn0search4turn0search19turn0search23turn0search27  
- File/Directory level permissions via NTFS ACLs and how they combine with share-level RBAC. citeturn0search19  
- Scenarios where you should choose identity-based access instead of keys or SAS.

---

## D. Exam mindset for this section

When you see an AZ-104 question that includes **Storage + Security**, ask yourself:

1. **Is the question about NETWORK or IDENTITY?**
   - If the problem is “Who can access?”, think **keys / SAS / Entra / RBAC**.  
   - If the problem is “From where can they access?”, think **firewalls / VNets / private endpoints**.

2. **Is it short-lived and scoped, or long-lived and broad?**
   - Short-lived, specific client → SAS (prefer **user delegation SAS** if Blob + Entra). citeturn0search1turn0search6turn0search11turn0search21  
   - Long-lived, internal system → SAS with **stored access policy** or **managed identity + Entra auth**.

3. **Does the scenario mention “rotate keys”, “avoid sharing keys”, or “compliance”?**
   - Answer will usually involve **Key Vault**, **SAS**, or **Entra-based access**, not just handing out account keys. citeturn0search3turn0search8turn0search21

4. **Does the scenario mention Windows / SMB / file shares?**
   - Think **Azure Files identity-based access**, **RBAC share roles**, and **NTFS ACLs**, not blob SAS. citeturn0search4turn0search9turn0search19turn0search30

Study each of the five detailed files in this folder with that mindset, and you’ll have a strong command of **Configure access to storage** for the AZ-104 exam.
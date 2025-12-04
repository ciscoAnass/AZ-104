# Configure Access to Storage

## 1️⃣ Big Picture: Why Network-Control Storage? 🤔

### Purpose

- Protect Azure Storage **from unauthorized network access**.
    
- Limit exposure → **reduce attack surface** (don’t let anyone on the Internet hit your storage).
    
- Enforce **network segmentation** (who can talk to who).
    
- Comply with **security & compliance standards** (e.g., data should only move inside your corporate/private network).
    
- Prevent **data exfiltration** (no data leaks to the Internet).
    

---

## 2️⃣ Three Core Network Access Control Methods

Azure Storage provides **three main layers** of network control.  
Each gives different balance of 🔒 security vs 🌐 accessibility vs ⚙️ manageability.

---

### 🧱 1. Storage Firewalls & IP Network Rules

**Concept:**  
You explicitly allow or deny access based on **public IP addresses** or **IP ranges**.

**How it works:**

- The storage account has a built-in **firewall**.
    
- By default, all networks are **denied**.
    
- You can **allow specific public IPs** (e.g., your office or on-prem datacenter).
    

**Example:**

- Allow: `20.85.33.0/24` (corporate VPN range).
    
- Deny: All others.
    

**Exam Tip 🧠:**  
If traffic comes from an _unapproved IP_, it gets **HTTP 403 (Forbidden)**.

**Pros ✅:**

- Simple to set up.
    
- Useful for quick restrictions (e.g., “Only office network allowed”).
    

**Cons ❌:**

- Only works with **public IPs**.
    
- Doesn’t integrate deeply with Azure VNets (less flexible).
    
- Harder to manage at scale.
    

**Best for:**  
Basic lockdown or hybrid setups with known IPs.

---

### 🌐 2. Virtual Network Rules (Service Endpoints)

**Concept:**  
You connect your **Azure Virtual Network (VNet)** directly to the **Azure Storage service** over the Microsoft backbone network — _not via public Internet_.

**Mechanism:**

- Enable a **Service Endpoint** on a VNet subnet for `Microsoft.Storage`.
    
- Then, configure your storage account to allow traffic **only** from that subnet.
    
- Traffic flows privately (no Internet exposure), but the storage account still has a **public IP**.
    

**Flow Example:**  
`VNet → Service Endpoint → Azure Storage (public IP, secured path)`

**Pros ✅:**

- Data stays on Microsoft’s backbone (secure & fast).
    
- Integrates with VNets (more control).
    
- Easy to configure from portal or CLI.
    

**Cons ❌:**

- Storage still has a _public endpoint_ (can still be probed).
    
- Doesn’t give a private IP to the storage account.
    
- Harder to isolate completely from the Internet.
    

**Best for:**  
When you want VNet-level security but still need public endpoint compatibility.

---

### 🕵️‍♀️ 3. Private Endpoints (Azure Private Link)

**Concept:**  
Provides a **private IP** in your VNet that maps to your **storage account**.  
So your storage is fully reachable **only via private network** — **no public Internet access** at all.

**Mechanism:**

- Create a **Private Endpoint** in a subnet.
    
- Azure assigns a **private IP (10.x.x.x)** to the storage account.
    
- DNS resolves the storage account name to that private IP (via Private DNS Zone).
    

**Flow Example:**  
`VNet → Private Endpoint (private IP) → Azure Storage (private connection)`

**Pros ✅:**

- Highest security (completely removes public exposure).
    
- Traffic is 100% private over Microsoft backbone.
    
- Prevents data exfiltration to external accounts.
    

**Cons ❌:**

- Slightly more complex setup (DNS integration required).
    
- Limited manageability (private access only).
    
- More overhead for multi-region/multi-network scenarios.
    

**Best for:**  
Highly secure, enterprise-grade environments (banks, gov, healthcare).

---

## 3️⃣ Security vs Manageability vs Connectivity ⚖️

|Method|Security 🔒|Manageability ⚙️|Connectivity 🌐|Key Note|
|---|---|---|---|---|
|**IP Rules / Storage Firewall**|Medium|Easy|Global (Public IPs)|Simple but not deeply integrated with VNets|
|**VNet Rules / Service Endpoints**|High|Moderate|Azure VNets only|Keeps traffic inside Azure backbone|
|**Private Endpoints (Private Link)**|Very High|Complex|Fully Private|No public exposure at all|

---

## 4️⃣ Example Decision Flow 🧭

**Scenario 1:** You need quick protection for dev storage —> ✅ Use **IP rules**.  
**Scenario 2:** You have Azure VNets and want secure backbone traffic —> ✅ Use **Service Endpoints**.  
**Scenario 3:** You must isolate data completely —> ✅ Use **Private Endpoints**.

---

## 5️⃣ Key Exam Notes 🧠

- By default, storage allows all network access — secure it explicitly.
    
- Service Endpoints = use Azure backbone but still public endpoint.
    
- Private Endpoint = gives private IP, disables public access.
    
- You can mix: firewall + endpoint rules + SAS tokens (next topic).
    
- Always **test connectivity** using `nslookup` or `az network private-endpoint show`.
    

---

## 6️⃣ Visual Summary 🧩

 `┌─────────────────────────────────────┐  │           Azure Storage             │  ├─────────────────────────────────────┤  │ 🔒 IP Network Rules (Public IPs)     │  → Allow only known public IPs  │ 🌐 Service Endpoints (VNet Rules)    │  → Secure traffic via Azure backbone  │ 🕵️‍♂️ Private Endpoints (Private Link) │  → Private IP, no Internet access  └─────────────────────────────────────┘`

---

✅ **Takeaway Summary:**  
Network-control storage = control who can talk to storage **at the network layer**, not just at the identity layer.  
It’s about _where_ requests come from, not _who_ makes them.
# Implement Azure Bastion

_AZ-104 exam objective: Implement secure access to virtual machines in virtual networks using Azure Bastion._

---

## 1. Why Azure Bastion?

Typical (bad) pattern for VM admin access:

- Expose **RDP (3389)** or **SSH (22)** to the Internet using a public IP on each VM.
- This invites:
  - Port scans
  - Brute-force attacks
  - RDP/SSH exploits

**Azure Bastion** fixes this:

- It is a **fully managed PaaS service** that provides secure RDP/SSH access to VMs **without** exposing them to the Internet.
- You connect over **TLS (HTTPS, port 443)** to Azure Bastion via the Azure portal (or native client).
- Bastion then connects to your VM using **private IP** inside the VNet.

> Result: VMs **don’t need public IPs**, and you still have convenient RDP/SSH access.

---

## 2. Azure Bastion architecture

### 2.1 High-level flow

```text
Admin PC
   │
   │ HTTPS (443) over Internet
   ▼
Azure Bastion (PaaS)
   │
   │ RDP/SSH over private IP
   ▼
Virtual Machine in your VNet
```

Key points:

- Bastion is deployed **into your virtual network**.
- It uses a dedicated subnet called **AzureBastionSubnet**.
- You connect via the **Azure portal** using an HTML5 client (or native RDP/SSH via certain features).
- The VM only needs a **private IP**; no public IP is required.

### 2.2 AzureBastionSubnet requirements

When using **Basic/Standard/Premium SKUs**:

- Subnet name **must** be exactly `AzureBastionSubnet`.
- Subnet prefix must be **/26 or larger** (/26, /25, /24, etc.) to allow for enough Bastion instances.
- Subnet must be in the **same VNet and resource group** as Bastion.
- Subnet is reserved for Bastion (no other resources in it).

> AZ‑104 tip: Questions often mention **AzureBastionSubnet** and the requirement for a **dedicated subnet**.

---

## 3. Azure Bastion SKUs (conceptual)

You don’t need to memorize every tiny feature difference for AZ‑104, but you should know the basics:

- **Developer SKU**
  - Lightweight, free tier for dev/test.
  - No dedicated host in your VNet.
  - Limited features, no scaling.
- **Basic SKU**
  - Core Bastion functionality.
  - Provides secure RDP/SSH to VMs in the VNet.
  - Fixed small number of instances.
- **Standard SKU**
  - Adds **host scaling**, **custom ports**, **shareable links**, more advanced features.
- **Premium SKU**
  - Adds advanced features like **session recording** and **private-only deployment**.

General points:

- You can **upgrade** SKUs (e.g. Basic → Standard → Premium), but not downgrade without redeploying.
- Pricing is per hour + data transfer; Bastion costs money as long as it is deployed.

For AZ‑104, what matters most is:

- Bastion provides **secure RDP/SSH** over **TLS 443**.
- It removes the need for **public IPs** and public RDP/SSH ports on VMs.
- It uses a **dedicated subnet** named `AzureBastionSubnet`.

---

## 4. Deploy Azure Bastion in the Azure portal

### 4.1 Prerequisites

- An existing **VNet** with at least one **subnet** containing the VMs you want to manage.
- Ability to create a new subnet named **AzureBastionSubnet**.
- A **Public IP address** (Standard SKU, static) for Bastion, or permission to create one.

### 4.2 Step-by-step deployment

1. In the portal, search for **Bastion** and select **Bastion**.
2. Click **+ Create**.
3. On the **Basics** tab:
   - Subscription and Resource group: choose appropriate values.
   - Name: e.g. `bastion-hub`.
   - Region: same region as the target VNet.
   - Tier / SKU: choose **Standard** (common default) or Basic/Developer as needed.
4. **Virtual network**:
   - Select existing VNet (e.g. `vnet-hub`).
5. **Subnet**:
   - If `AzureBastionSubnet` does not exist, click **Manage subnet configuration** and create a new subnet:
     - Name: `AzureBastionSubnet`
     - Address range: e.g. `10.0.255.0/26`
6. **Public IP address**:
   - Create a new public IP.
   - Ensure **SKU = Standard** and **Assignment = Static**.
7. Optional: Configure advanced settings (scaling, availability zones, etc. depending on SKU).
8. Click **Review + create** → **Create**.

Deployment usually takes a few minutes.

---

## 5. Connect to a VM using Azure Bastion

Once Bastion is deployed in a VNet that contains the VM (or is peered to it), you can connect:

### 5.1 Via Azure portal

1. Go to **Virtual machines** → select target VM.
2. Click **Connect** → choose **Bastion**.
3. If prompted, select the Bastion host (if multiple) and confirm.
4. Choose authentication method:
   - Windows: Username + password, or Azure AD (if configured).
   - Linux: Username + SSH private key.
5. Click **Connect**.

A new browser tab opens with an embedded RDP/SSH session over **HTTPS (443)**.

### 5.2 Via native clients (Standard/Premium features)

For higher SKUs, Azure Bastion can also support:

- Connecting using **native RDP/SSH clients** (via tunnel).
- **Shareable links** so other users can connect without portal access.

For AZ‑104 you mainly just need the **portal experience**.

---

## 6. Azure Bastion and NSGs

Azure Bastion uses private IPs to connect to VMs inside your VNet. NSGs still control the traffic flows.

### 6.1 NSG for the AzureBastionSubnet

You can attach an NSG to the `AzureBastionSubnet` to restrict traffic, but you must allow the required ports and service tags for Bastion to function (control plane, AzureCloud, etc.). If you block required traffic, Bastion may not deploy correctly or may stop working.

**Important simplification for AZ‑104:**

- On exam questions, focus on the idea that:
  - Bastion requires **HTTPS 443 inbound** to its **public IP**.
  - Bastion requires **outbound RDP/SSH (3389/22)** to VMs via **private IPs**.

### 6.2 NSG on VM subnets / NICs

To allow Bastion to connect to your VMs:

- NSG on **VM subnet/NIC** must allow:
  - Inbound:
    - Protocol: TCP
    - Ports: `3389` for Windows, `22` for Linux (or custom ports if configured in Bastion).
    - Source: typically `VirtualNetwork` (or the source subnet if you want to be stricter).

You **do not** need to allow any public IP ranges from the Internet for RDP/SSH. Bastion hides those ports.

> Best practice: Only allow RDP/SSH from **Bastion** (i.e. from inside the VNet), not from the Internet.

---

## 7. Azure Bastion with virtual network peering

Bastion can connect to VMs in:

- The **local VNet** where it is deployed.
- **Peered VNets**, if configured and allowed by NSGs and routes.

Common pattern:

```text
VNet-hub (central)
  └─ AzureBastionSubnet + Bastion

VNet-spoke1 (peered)
  └─ App VMs

VNet-spoke2 (peered)
  └─ DB VMs
```

Admins connect to Bastion in the **hub** and from there can RDP/SSH into VMs in the spoke VNets via private IP (no public IPs on VMs).

For this to work:

- VNet peering must allow traffic between VNets.
- NSGs must allow Bastion subnet → VM subnet traffic on RDP/SSH ports.

---

## 8. Security and best practices

- **Do not assign public IPs** to your VMs if all admin access is via Bastion.
- Block inbound RDP/SSH from Internet in NSGs and in any Network Virtual Appliances.
- Use **Just‑in‑Time (JIT) VM access** if you’re using public RDP/SSH; or better, avoid public exposure entirely with Bastion.
- Restrict access to Bastion itself using:
  - Azure RBAC (who can use or manage the Bastion resource)
  - Possibly NSGs on the Bastion subnet to limit which source IPs can hit the Bastion public IP (if required).
- Monitor Bastion usage with **logs and diagnostics**:
  - Sign‑in events
  - Connection attempts
- Delete Bastion in test environments when you’re not using it to reduce costs.

---

## 9. AZ‑104 exam tips

- **Purpose:** Azure Bastion gives secure RDP/SSH access to Azure VMs over **HTTPS 443**, without public IPs on the VMs.
- **Subnet:** Requires a dedicated subnet named **AzureBastionSubnet**.
- **Connection path:** Admin → Azure portal → Bastion (public IP) → VM (private IP).
- **VM requirements:** Needs only a **private IP** and NSG rules allowing RDP/SSH from inside the VNet.
- **When to choose Bastion vs public IP:**
  - Choose **Bastion** when the requirement is “no RDP/SSH from Internet” or “no public IPs on VMs”.
- **Peering:** Bastion can reach VMs in **peered VNets** (subject to NSGs and routes).

If a question asks for “secure administrative access to VMs without exposing them to the internet”, the correct answer is almost always **Azure Bastion**.

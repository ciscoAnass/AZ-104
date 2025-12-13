# Create and Configure Virtual Networks and Subnets

> AZ-104 Objective: **Create and configure virtual networks and subnets**

---

## 1. What is a Virtual Network (VNet)?

An **Azure Virtual Network (VNet)** is a private, isolated network in Azure where you can place your resources (VMs, App Services with VNet integration, Application Gateways, etc.).  
It is similar to a network you would create in your own datacenter.

Key ideas:

- Uses **private IP ranges** (RFC1918):
  - 10.0.0.0 – 10.255.255.255
  - 172.16.0.0 – 172.31.255.255
  - 192.168.0.0 – 192.168.255.255
- Can optionally use **IPv6** address spaces too.
- Divided into **subnets** to organize and secure workloads.
- Supports **hybrid connectivity** (VPN, ExpressRoute) and **peering** with other VNets.

**Mental picture:**

```text
Azure Subscription
└── Virtual Network: vnet-hospital-weu (10.10.0.0/16)
    ├── Subnet: snet-front (10.10.1.0/24)  → Web servers
    ├── Subnet: snet-app   (10.10.2.0/24)  → Application servers
    └── Subnet: snet-db    (10.10.3.0/24)  → Databases
```

---

## 2. Planning Address Spaces and Subnets

Before you click “Create VNet”, you must plan your IP ranges.  
Changing address spaces later (especially in production) is painful.

### 2.1 Address Space (VNet-wide)

- Defined as a **CIDR block**, like `10.10.0.0/16`.
- A VNet can have **one or more** address spaces.
- Address spaces **cannot overlap** with:
  - Other VNets you plan to peer with.
  - On‑premises networks connected via VPN/ExpressRoute.

**Exam rule:**  
> Overlapping IP ranges = **no VNet peering** and problems with VPN routes.

### 2.2 Subnet Planning

A **subnet** is a logical segment inside a VNet.

Why subnets?

- Group similar workloads (web, app, DB).
- Apply **NSGs** (Network Security Groups) per subnet.
- Delegate a subnet to specific Azure PaaS services (App Service Environment, Azure Bastion, etc.).
- Control routing (User Defined Routes) per subnet.

**Subnet CIDR rules:**

- Must be **contained** in the VNet address space.
- Subnets in the same VNet **must not overlap**.
- Azure reserves **5 IP addresses** in each subnet:
  - Network address (e.g., 10.10.1.0)
  - First 3 IPs for Azure internal use
  - Broadcast address (e.g., 10.10.1.255) – conceptually reserved

Example:
- VNet: `10.10.0.0/16`
- Subnets:
  - `10.10.1.0/24` (snet-front)
  - `10.10.2.0/24` (snet-app)
  - `10.10.3.0/24` (snet-db)

Subnet size recommendations:

- **/24 (256 IPs)** is common for small/medium workloads.
- Use smaller or bigger subnet masks based on expected growth.
- Remember: some services (AKS, Application Gateway, Bastion) require many IPs.

**Exam tip:** If question asks which subnet size is suitable for 100 VMs with room to grow → `/24` is usually safe.

---

## 3. Creating a VNet and Subnets (Portal)

### 3.1 Create a VNet

1. Go to **Azure portal** → **Create a resource** → search **Virtual Network**.
2. Click **Create**.
3. **Basics tab:**
   - Subscription & Resource group (create or select existing).
   - Name: `vnet-hospital-weu` (good naming = `vnet-<app>-<region>`).
   - Region: e.g., `West Europe` (choose region close to users).
4. **IP Addresses tab:**
   - IPv4 address space: `10.10.0.0/16`.
   - (Optional) Add IPv6: e.g., `fd00:db8:1234::/48`.
5. **Security tab:**
   - You can enable DDoS protection standard or Microsoft Defender for Cloud (not required to create VNet).
6. **Review + create** → **Create**.

### 3.2 Add Subnets (Portal)

After VNet is created:

1. Open your VNet → **Subnets** in left menu.
2. Click **+ Subnet**.
3. Example subnets:
   - `snet-front` → `10.10.1.0/24`
   - `snet-app` → `10.10.2.0/24`
   - `snet-db` → `10.10.3.0/24`
4. For each subnet, you can optionally configure:
   - **Network security group** (NSG)
   - **Route table** (for UDRs)
   - **Service endpoints**
   - **Delegations** (for special Azure services)
5. Click **Save**.

---

## 4. Creating VNets and Subnets with Azure CLI

CLI is very exam-relevant. Remember the **pattern**.

### 4.1 Create Resource Group

```bash
az group create \
  --name rg-network-weu \
  --location westeurope
```

### 4.2 Create VNet + First Subnet

```bash
az network vnet create \
  --resource-group rg-network-weu \
  --name vnet-hospital-weu \
  --address-prefix 10.10.0.0/16 \
  --subnet-name snet-front \
  --subnet-prefix 10.10.1.0/24
```

This command creates:

- Resource group (if not existing)
- VNet (`10.10.0.0/16`)
- Subnet `snet-front` (`10.10.1.0/24`)

### 4.3 Add More Subnets

```bash
az network vnet subnet create \
  --resource-group rg-network-weu \
  --vnet-name vnet-hospital-weu \
  --name snet-app \
  --address-prefixes 10.10.2.0/24

az network vnet subnet create \
  --resource-group rg-network-weu \
  --vnet-name vnet-hospital-weu \
  --name snet-db \
  --address-prefixes 10.10.3.0/24
```

### 4.4 Show VNet Details

```bash
az network vnet show \
  --resource-group rg-network-weu \
  --name vnet-hospital-weu \
  --output table
```

---

## 5. Configuring Subnets: NSGs, Route Tables, Service Endpoints, Delegations

Subnets are more than just IP ranges. You attach security and routing.

### 5.1 Attach a Network Security Group (NSG)

An **NSG** is a firewall-like resource that filters traffic based on rules (source, destination, port, protocol).

Attach NSG to subnet using CLI:

```bash
# Create NSG
az network nsg create \
  --resource-group rg-network-weu \
  --name nsg-front

# Associate NSG with subnet
az network vnet subnet update \
  --resource-group rg-network-weu \
  --vnet-name vnet-hospital-weu \
  --name snet-front \
  --network-security-group nsg-front
```

You can also associate NSGs at the **NIC** level.

**Exam tip:** When troubleshooting connectivity, always check NSG rules at both **subnet** and **NIC** levels.

### 5.2 Route Tables (User Defined Routes - UDR)

For now just remember: you can attach a route table to a subnet to override default routing (force internet traffic through a firewall, etc.).  
Details are deep in the dedicated **User-defined routes** file.

Basic attachment:

```bash
az network route-table create \
  --resource-group rg-network-weu \
  --name rt-hub

az network vnet subnet update \
  --resource-group rg-network-weu \
  --vnet-name vnet-hospital-weu \
  --name snet-app \
  --route-table rt-hub
```

### 5.3 Service Endpoints

**Service endpoints** extend your VNet’s identity to Azure PaaS services (e.g., Storage, SQL).  
Traffic to these services goes over the Azure backbone instead of public internet.

Config at subnet level (Portal: Subnet → Service endpoints).  
Example (CLI):

```bash
az network vnet subnet update \
  --resource-group rg-network-weu \
  --vnet-name vnet-hospital-weu \
  --name snet-app \
  --service-endpoints Microsoft.Storage
```

### 5.4 Subnet Delegations

Some Azure services need full control over a subnet (e.g., **Azure Bastion**, **App Service Environment v3**, **Azure Container Apps**).  
For that you **delegate** the subnet.

Example (CLI):

```bash
az network vnet subnet update \
  --resource-group rg-network-weu \
  --vnet-name vnet-hospital-weu \
  --name snet-ase \
  --delegations Microsoft.Web/hostingEnvironments
```

**Exam (conceptual) question example:**  
> You must create an Azure Bastion host. What is required in the VNet?  
Answer: A dedicated subnet named **AzureBastionSubnet** with at least /26 size.

---

## 6. IPv6 and Dual-Stack VNets (Exam-Level Overview)

Azure VNets can be:

- **IPv4-only**
- **IPv6-only** (rare)
- **Dual stack** (IPv4 + IPv6)

For dual stack:

- Add IPv6 address space: e.g., `fd00:db8:1234::/48`
- Each subnet has **both** an IPv4 and IPv6 range.

IP version matters for:

- Public IPs (IPv4, IPv6, or both).
- Load balancers and frontends.

For AZ‑104 you typically need to know **that it exists** and that you configure IPv6 on VNet + subnet.

---

## 7. VNet Integration with Other Services (High-Level)

You will see VNets appear in many other AZ‑104 areas:

- **Virtual Machines:** each NIC must be connected to a subnet inside a VNet.
- **App Service**: VNet integration to call internal services.
- **Azure SQL Managed Instance**: deployed in a dedicated subnet.
- **AKS (Kubernetes)**: uses VNets and subnets for nodes and pods.
- **VPN Gateways / ExpressRoute Gateways**: placed in dedicated gateway subnets (`GatewaySubnet`).

**Special subnet names to remember:**

| Service           | Required subnet name        |
|-------------------|----------------------------|
| VPN Gateway       | `GatewaySubnet`            |
| Azure Bastion     | `AzureBastionSubnet`       |
| Firewall          | no fixed name, but often `AzureFirewallSubnet` (recommended) |

Exam questions often check if you remember **GatewaySubnet** and **AzureBastionSubnet** names.

---

## 8. Common Design Patterns

### 8.1 Hub-and-Spoke Topology

```text
            On-premises
                │ VPN/ER
                ▼
           VNet-hub (10.0.0.0/16)
            ├─ Firewall/NVA subnet
            └─ Shared services subnet
             ▲           ▲
             │           │
          Peering     Peering
             │           │
     VNet-spoke1    VNet-spoke2
   (App1 10.1.0.0/16) (App2 10.2.0.0/16)
```

- Hub: shared services, VPN/ER gateway, firewall.
- Spokes: application VNets.
- Uses **VNet peering** (next file).

### 8.2 Single VNet with Multiple Subnets

Simple, small environments:

```text
VNet-prod (10.10.0.0/16)
├─ snet-front (10.10.1.0/24) → NSG-front
├─ snet-app  (10.10.2.0/24)  → NSG-app
└─ snet-db   (10.10.3.0/24)  → NSG-db
```

Good for small companies or non-critical workloads.

---

## 9. Best Practices

1. **Avoid overlapping IP ranges**  
   - Plan for future peering and hybrid connectivity.
2. **Reserve address space for growth**  
   - Use /16 for VNet, /24 for subnets, then add more subnets later.
3. **Use clear naming conventions**  
   - `vnet-<env>-<region>`, `snet-<tier>-<function>`.
4. **Separate tiers into different subnets**  
   - Web, App, DB → easier security with NSGs.
5. **Use NSGs at subnet level for broad rules**  
   - Optionally refine at NIC level.
6. **Dedicated subnets for special services**  
   - Bastion, Gateway, Firewall, etc.
7. **Document your IP plan**  
   - Important in large environments and for the exam scenarios.

---

## 10. Exam Tips and Sample Questions

### Quick Memory Hooks

- VNet = **private network boundary**.
- Subnet = **segment** within a VNet.
- Azure reserves **5 IPs** per subnet.
- Special subnet names: `GatewaySubnet`, `AzureBastionSubnet`.
- No **overlapping** address spaces for **peering** and **VPN**.

### Sample Question 1

**Question:**  
You need to design a network in Azure for 3 tiers: web, app, and database. The solution must support up to 150 VMs, allow NSG rules between tiers, and possibly connect to on‑premises later. What should you do?

**Answer (idea):**

- Create one VNet with address space `10.10.0.0/16`.
- Create three /24 subnets: `10.10.1.0/24`, `10.10.2.0/24`, `10.10.3.0/24`.
- Place each tier in its own subnet and apply NSGs per subnet.
- Because address space is /16, you have room for more subnets and non-overlapping IPs for VPN later.

### Sample Question 2

**Question:**  
You created a subnet with prefix `10.0.0.0/29`. How many usable IP addresses are available for your VMs?

**Explanation:**  
/29 = 8 IPs total. Azure reserves 5 → usable = **3** IPs.

### Sample Question 3

**Question:**  
You need to deploy an Azure VPN Gateway in an existing VNet. What is required?

**Answer:**  
Create a subnet named **GatewaySubnet** with an appropriate prefix (e.g., /27 or /28) and deploy the VPN Gateway into that subnet.

---

If you fully understand this file, you are strong on **VNets and subnets**, which is foundational for all networking topics in AZ‑104.

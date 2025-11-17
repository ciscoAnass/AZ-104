# Configure User-Defined Network Routes (UDRs)

> AZ-104 Objective: **Configure user-defined network routes**

---

## 1. Routing Basics in Azure VNets

Azure **automatically** creates routes so resources in a VNet can talk to each other and to the internet (when allowed). These are called **system routes**.

Typical system routes:

| Destination         | Next hop type      | Meaning                                  |
|--------------------|--------------------|-------------------------------------------|
| VNet address space | Virtual network    | Routes inside the same VNet/subnets       |
| 0.0.0.0/0          | Internet           | Default route to internet (if allowed)    |
| On‑prem networks   | Virtual network gateway | When VPN/ER gateway is present      |

**User-defined routes (UDRs)** let you **override** these system routes.

Use cases:

- Force internet traffic through a **firewall** or NVA.
- Implement **hub-and-spoke** routing.
- Prevent direct internet access.
- Send specific traffic through on‑premises.

---

## 2. Route Tables and UDRs

A **route table** is an Azure resource that:

- Contains one or more **routes** (User-defined routes).
- Is associated with **one or more subnets**.
- Affects traffic **leaving** that subnet (outbound).

Each route has:

- **Address prefix** (destination CIDR), e.g. `0.0.0.0/0`, `10.2.0.0/16`.
- **Next hop type** (where to send traffic).

### 2.1 Next Hop Types

Common next hop types in AZ-104:

| Next hop type          | Description                                           | Example                                              |
|------------------------|-------------------------------------------------------|------------------------------------------------------|
| Virtual network        | Default route inside VNet                             | System route for intra‑VNet communication            |
| Internet               | Send traffic to internet                              | Default 0.0.0.0/0 route (if no VPN attached)         |
| Virtual network gateway| Send to VPN/ER gateway                               | For hybrid connectivity                              |
| Virtual appliance      | Send to an IP of NVA (firewall/router) in Azure      | `10.0.1.4` = firewall private IP                     |
| None                   | Drop traffic                                         | Used to **black-hole** traffic                       |

**Exam tip:**  
Virtual appliance = IP address of an Azure VM or NVA performing routing or firewalling.

---

## 3. Creating a Route Table and UDRs (Portal)

Scenario: You have a **spoke subnet** with VMs that should send all internet-bound traffic through a **firewall** in a hub subnet.

```text
VNet-hub (10.0.0.0/16)
├─ snet-firewall (10.0.1.0/24)
│    └── Firewall NVA (10.0.1.4)
└─ snet-shared (10.0.2.0/24)

VNet-spoke1 (10.1.0.0/16)
└─ snet-app (10.1.1.0/24)
```

Step-by-step:

1. In the portal, search **Route tables** → **Create**.
2. **Basics:**
   - Resource group: `rg-network-hub`
   - Name: `rt-spoke1`.
   - Region: match your VNet region (e.g., West Europe).
3. Click **Review + Create** → **Create**.

4. Open the created route table `rt-spoke1` → **Routes** → **+ Add**.
5. Create a route:
   - Route name: `default-to-firewall`.
   - Address prefix: `0.0.0.0/0` (all IPv4 traffic).
   - Next hop type: **Virtual appliance**.
   - Next hop address: `10.0.1.4` (firewall’s private IP).
6. Save.

7. Now associate the route table with the subnet in the spoke:
   - In `rt-spoke1`, go to **Subnets** → **+ Associate**.
   - Choose virtual network: `vnet-spoke1`.
   - Choose subnet: `snet-app`.
   - Save.

Result: any traffic leaving `snet-app` destined for **internet** will go to **firewall 10.0.1.4** instead of directly to internet.

---

## 4. Creating Route Tables and UDRs with Azure CLI

### 4.1 Create a Route Table

```bash
az network route-table create \
  --resource-group rg-network-hub \
  --name rt-spoke1 \
  --location westeurope
```

### 4.2 Add a Route to Firewall

```bash
az network route-table route create \
  --resource-group rg-network-hub \
  --route-table-name rt-spoke1 \
  --name default-to-firewall \
  --address-prefix 0.0.0.0/0 \
  --next-hop-type VirtualAppliance \
  --next-hop-ip-address 10.0.1.4
```

### 4.3 Associate Route Table with Subnet

```bash
az network vnet subnet update \
  --resource-group rg-network-spoke1 \
  --vnet-name vnet-spoke1 \
  --name snet-app \
  --route-table rt-spoke1
```

Use `az network route-table show` or the portal to verify.

---

## 5. How Routes Are Applied: Priority and Combination

For each subnet, Azure builds an **effective route table** combining:

1. System routes (default VNet, internet, gateway).
2. **BGP routes** (from VPN/ER gateways, if any).
3. **User-defined routes** from associated route table.

Precedence (simplified for exam):

- **User-defined routes** override system routes and BGP routes when prefixes overlap.
- More **specific prefix** wins (longer mask).
  - Example: `/24` beats `/16` which beats `/0`.

**Example:**

- System route: `0.0.0.0/0` → Internet.
- UDR: `0.0.0.0/0` → VirtualAppliance 10.0.1.4.

Result: traffic uses **VirtualAppliance**.

---

## 6. Typical UDR Scenarios for AZ-104

### 6.1 Force Tunneling to On‑Premises

Goal: send all internet-bound traffic from Azure VMs through your **on‑prem firewall** instead of Azure internet.

Design:

- VNet has a **VPN gateway**.
- There is an on‑prem network connected via VPN.
- You create a **route table** and route:
  - `0.0.0.0/0` → Next hop type: **Virtual network gateway**.
- Associate this route table with the subnets whose traffic must be forced through VPN.

```text
Azure subnet ──> VPN Gateway ──> On-prem firewall ──> Internet
```

**Exam tip:** Force tunneling to on‑prem uses **Virtual network gateway** as next hop.

### 6.2 Hub-and-Spoke with Central Firewall

Goal: all spokes send traffic (to internet or other spokes) through a **firewall in hub**.

- Each spoke subnet has a route table.
- For example:
  - Destination `0.0.0.0/0` → Next hop: firewall IP (Virtual appliance).
  - Destination other spokes (10.2.0.0/16, 10.3.0.0/16) → Next hop: firewall IP.

### 6.3 Black-Hole Route (Drop Traffic)

Use `Next hop type = None` to **drop traffic**.

Example: You want to ensure that VMs in a subnet **never** reach a specific subnet `10.20.0.0/16`.

- Create UDR:
  - Address prefix: `10.20.0.0/16`
  - Next hop type: **None**
- Associate with the subnet.

All traffic to `10.20.0.0/16` from that subnet is dropped.

### 6.4 Service Chaining via NVA

You can chain services like:

```text
Spoke subnet ──> Firewall NVA ──> Azure Firewall ──> Internet
```

- Use multiple UDRs to send traffic through multiple NVAs.

For AZ‑104, understand conceptually that UDRs help implement these chained paths.

---

## 7. Viewing and Troubleshooting Routes

### 7.1 Effective Routes (Portal)

For a VM’s NIC:

1. Go to the **VM** → **Networking**.
2. Click on the **network interface**.
3. In left menu, choose **Effective routes**.

You will see:

- System routes.
- BGP routes (if any).
- User-defined routes.

You can see which route is active for a destination.

### 7.2 Network Watcher: Next Hop

Using **Network Watcher**, you can check which **next hop** is being used for a specific destination.

CLI example:

```bash
az network watcher show-next-hop \
  --resource-group rg-network-spoke1 \
  --vm vm-app-01 \
  --source-ip 10.1.1.4 \
  --destination-ip 8.8.8.8
```

This command shows:

- Which route is applied.
- Next hop type (Internet, VirtualAppliance, etc.).

(Details of Network Watcher are covered deeper in the troubleshooting file.)

### 7.3 Common Issues

1. Route table attached to **wrong subnet** or **not attached at all**.
2. Wrong **next hop IP** (e.g., firewall IP changed).
3. Missing route for specific address space (on‑prem or other spokes).
4. Overly broad UDR (e.g., `0.0.0.0/0` to firewall, but firewall has no path to some networks).

---

## 8. Interaction with Peering and Gateways

- With **VNet peering**, system routes are added automatically to reach peered VNet.
- UDRs can override this:
  - You can force traffic that would normally go directly to peered VNet to instead go via NVA.

Example:

```text
Spoke1 (10.1.0.0/16) ──peered── Hub (10.0.0.0/16) ──peered── Spoke2 (10.2.0.0/16)
```

By default, Spoke1 can reach Spoke2 via peering if allowed.  
But you can attach a route table to Spoke1:

- Destination: `10.2.0.0/16`
- Next hop: Virtual appliance (firewall IP in hub)

Now traffic goes **Spoke1 → Firewall → Spoke2**.

**Exam concept:**  
> UDR + VNet peering + firewall = classic hub-and-spoke design.

---

## 9. Best Practices

1. **Keep UDRs simple and documented**  
   - Many complex routes are hard to troubleshoot.
2. **Use specific prefixes** for exceptions and broader prefixes for defaults.
3. **Always test routes** using Network Watcher tools (Next hop, IP flow verify).
4. **Avoid conflicting routes** across multiple route tables.
5. **Design with security in mind**  
   - Route outbound traffic through firewalls or security services when necessary.
6. **Use Azure Firewall or appliance in hub** for central control of outbound/inbound flows.

---

## 10. Exam Tips and Sample Questions

### Memory Hooks

- Route table + UDRs = overriding system routing.
- Next hop for firewall = **Virtual appliance**.
- Force tunneling to on‑prem = **Virtual network gateway** as next hop.
- Black-hole route = **Next hop: None**.

### Sample Question 1

**Question:**  
You need to force all internet-bound traffic from a subnet to an on‑premises firewall over VPN. What should you configure?

**Answer:**

- Create a route table.
- Add route `0.0.0.0/0` with next hop type **Virtual network gateway**.
- Associate route table with the subnet.

### Sample Question 2

**Question:**  
You create a UDR with:

- Address prefix: `0.0.0.0/0`
- Next hop: Virtual appliance `10.0.1.4`

Now your VMs in the subnet cannot reach the internet. What is the most likely cause?

**Explanation:**  
The firewall at `10.0.1.4` either:

- Has no outbound internet access, or
- Its own routing/NSGs are misconfigured.

The UDR correctly sends traffic to the firewall, but the path beyond the firewall is broken.

### Sample Question 3

**Question:**  
You want to drop all traffic from a subnet to address range `10.20.0.0/16`. Which configuration should you use?

**Answer:**

- Create UDR:
  - Address prefix: `10.20.0.0/16`
  - Next hop type: **None**
- Associate with the subnet.

---

If you fully understand how UDRs and route tables work, you will be able to design and troubleshoot many of the routing scenarios in AZ‑104.

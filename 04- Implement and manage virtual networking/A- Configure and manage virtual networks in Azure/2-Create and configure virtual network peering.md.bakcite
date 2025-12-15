# Create and Configure Virtual Network Peering

> AZ-104 Objective: **Create and configure virtual network peering**

---

## 1. What is VNet Peering?

**Virtual network peering** connects two Azure VNets so that they behave as if they were part of the same network.

- Traffic between peered VNets is **private** and stays on the **Azure backbone** (not over internet).
- Very **low latency** and **high bandwidth**.
- You can peer VNets in the **same region** or **different regions**.

Types:

1. **VNet peering** (same region)
2. **Global VNet peering** (different regions)

**Key concept:** After peering, VMs in VNet A can talk directly to VMs in VNet B using **private IPs**, as long as:

- IP ranges **do not overlap**.
- NSGs and routing allow traffic.

---

## 2. Requirements and Limitations

### 2.1 Requirements

- VNets must have **non-overlapping address spaces**.
- You need **Network Contributor** or higher permissions on both VNets (or proper delegated permission).
- Both VNets must be in the **same Azure AD tenant** for standard peering scenario (cross-tenant peering is possible but advanced).

### 2.2 Limitations / Behaviors

- **No automatic transitive routing**:
  - If VNetA is peered with VNetB, and VNetB is peered with VNetC, A **cannot automatically** reach C.
  - To make A talk to C, you either:
    - Peer A–C directly; or
    - Use a **hub-and-spoke** design with a router/firewall and User Defined Routes.
- **Gateway transit** must be explicitly configured if you want one VNet to use another VNet’s VPN/ExpressRoute gateway.
- For **Global VNet peering**, some older features like Basic SKU load balancers may have limitations (exam will usually highlight this).

**Exam tip:**  
> Always check if address spaces overlap. If they do, peering is **not supported**.

---

## 3. Peering Scenarios

### 3.1 Simple Two-VNet Peering (Same Region)

```text
VNet-a (10.10.0.0/16)  ────── Peering ──────  VNet-b (10.20.0.0/16)
```

- VMs can communicate using private IPs.
- Traffic is routed over Azure backbone.

### 3.2 Global VNet Peering (Different Regions)

```text
VNet-eu (10.0.0.0/16, West Europe) ── Global Peering ── VNet-us (10.1.0.0/16, East US)
```

- Used for **multi-region** designs (DR, global access).
- Still uses Azure backbone (not public internet).

### 3.3 Hub-and-Spoke with Peering and Gateway Transit

```text
              On-premises
                   │
           VPN/ExpressRoute Gateway
                   │
             VNet-hub (10.0.0.0/16)
              /             \
             /               \
   Peering (use remote   Peering (use remote
     gateways)              gateways)
           /                     \
 VNet-spoke1 (10.1.0.0/16)   VNet-spoke2 (10.2.0.0/16)
```

- **Hub** has VPN/ER gateway.
- **Spokes** use **gateway transit** to reach on‑premises via hub.

---

## 4. Creating VNet Peering in the Portal

Assume:

- `vnet-hub-weu` (10.0.0.0/16)
- `vnet-spoke1-weu` (10.1.0.0/16)

### 4.1 From the First VNet

1. Go to **vnet-hub-weu** in the portal.
2. In left menu, choose **Peerings** → **+ Add**.
3. Configure:
   - **Peering link name (this VNet to remote)**: `hub-to-spoke1`
   - **Remote virtual network**: select `vnet-spoke1-weu`.
   - **Peering link name (remote to this VNet)**: `spoke1-to-hub` (portal creates both sides if same subscription/tenant).
   - Traffic settings:
     - Allow traffic from remote VNet? → **Yes** (default).
     - Allow forwarded traffic? (for NVAs) → depends on scenario.
     - Allow gateway transit? (if hub has gateway and you want spokes to use it) → **Yes** for hub side.
4. Click **Add**.

Portal will create **two** peering connections (one in each VNet).

**Exam note:**  
Peering is **not symmetric** until both directions are configured. Portal usually does both directions for same subscription, but CLI/PowerShell may require you to configure both sides.

---

## 5. Creating VNet Peering with Azure CLI

Assume:

- Resource group: `rg-network-weu`
- VNet 1: `vnet-hub-weu` (10.0.0.0/16)
- VNet 2: `vnet-spoke1-weu` (10.1.0.0/16)

### 5.1 Get VNet IDs (optional but useful)

```bash
hubId=$(az network vnet show \
  --resource-group rg-network-weu \
  --name vnet-hub-weu \
  --query id -o tsv)

spokeId=$(az network vnet show \
  --resource-group rg-network-weu \
  --name vnet-spoke1-weu \
  --query id -o tsv)
```

### 5.2 Create Peering: Hub → Spoke

```bash
az network vnet peering create \
  --name hub-to-spoke1 \
  --resource-group rg-network-weu \
  --vnet-name vnet-hub-weu \
  --remote-vnet $spokeId \
  --allow-vnet-access
```

### 5.3 Create Peering: Spoke → Hub

```bash
az network vnet peering create \
  --name spoke1-to-hub \
  --resource-group rg-network-weu \
  --vnet-name vnet-spoke1-weu \
  --remote-vnet $hubId \
  --allow-vnet-access
```

Now VNets are peered.

### 5.4 Gateway Transit Example (Hub-and-Spoke)

If **hub** has VPN gateway:

- On **hub** side peering, enable `--allow-gateway-transit`.
- On **spoke** side peering, enable `--use-remote-gateways`.

Example:

```bash
# Hub side
az network vnet peering create \
  --name hub-to-spoke1 \
  --resource-group rg-network-weu \
  --vnet-name vnet-hub-weu \
  --remote-vnet $spokeId \
  --allow-vnet-access \
  --allow-gateway-transit

# Spoke side
az network vnet peering create \
  --name spoke1-to-hub \
  --resource-group rg-network-weu \
  --vnet-name vnet-spoke1-weu \
  --remote-vnet $hubId \
  --allow-vnet-access \
  --use-remote-gateways
```

**Important constraints:**

- Only **one peering per VNet** can have `Use remote gateways = true`.
- VNet that **has the gateway** cannot use a remote gateway itself.

---

## 6. Security and Routing with VNet Peering

### 6.1 NSGs and UDRs Still Apply

Once peered, Azure adds **system routes** that point to the remote VNet.  
But NSGs and custom routes (UDRs) still control traffic.

- If NSG denies traffic between subnets, peering does not override it.
- You can use UDRs to send traffic between VNets through a firewall (NVA) instead of directly.

### 6.2 Forwarded Traffic

If you have a **Network Virtual Appliance (NVA)** doing routing or firewalling:

- You must allow **forwarded traffic** in the VNet peering configuration.
- Example: traffic from Spoke1, forwarded by firewall in Hub, then to Spoke2.

```text
Spoke1 ──> Hub (NVA) ──> Spoke2
```

In this design:

- On peering connections, enable **Allow forwarded traffic**.
- Use UDRs in spokes to send traffic to the NVA’s IP.

### 6.3 Peering and Service Endpoints / Private Endpoints

- Service endpoints are **per VNet/subnet**; they do not automatically flow across peering.
- Private endpoints (e.g., for Storage) have private IPs in a specific VNet/subnet, but you can **reach them from peered VNets** if routing and NSGs allow it.

---

## 7. Global VNet Peering

With **Global VNet Peering**, you connect VNets across regions.

Example:

```text
VNet-weu (10.0.0.0/16, West Europe)
    │   Global VNet Peering
    ▼
VNet-eus (10.1.0.0/16, East US)
```

Properties:

- Traffic stays on Azure backbone.
- You pay **egress**/ingress data transfer costs between regions (not exam-deep, but know that cross-region is not free).
- Limitations exist with some older/basic resources, but for AZ-104 the main point is **connectivity across regions with private IPs**.

Configuration steps are same as normal peering; you just select a VNet in a different region.

---

## 8. Peering vs. VPN vs. ExpressRoute

Understand when to use what:

| Feature                | VNet Peering                          | Site-to-Site VPN                          | ExpressRoute                      |
|------------------------|---------------------------------------|-------------------------------------------|-----------------------------------|
| Connects              | VNet↔VNet                              | On-prem↔VNet                              | On-prem↔VNet                      |
| Transport             | Azure backbone                         | Internet (IPsec tunnel)                   | Private dedicated circuit         |
| Use case              | Intra‑Azure connectivity               | Hybrid connectivity over internet         | High throughput, stable hybrid    |
| Encryption            | Internal (no IPsec)                    | IPsec encrypted                           | Private, may use MACsec optionally|
| Transitive routing    | No (by default, you must design it)   | Yes via on‑prem routing                   | Yes via on‑prem routing           |

**Exam patterns:**

- Azure-to-Azure, **same or different region**, private IP, low latency → **VNet Peering**.
- Connecting **on‑premises** to Azure → VPN or ExpressRoute.
- Need other VNet to use hub’s VPN gateway → **Gateway transit in peering**.

---

## 9. Troubleshooting VNet Peering

If two VMs in peered VNets cannot communicate:

1. Check **IP addresses and subnets**:
   - Are you using the correct private IPs?
   - Are address ranges overlapping? (If yes, peering may not even be possible.)
2. Check **Peering status**:
   - In portal → VNet → Peerings.
   - Status must be **Connected** on both sides.
3. Check **NSGs**:
   - On subnet and NIC.
   - Ensure inbound/outbound rules allow the traffic.
4. Check **Route tables (UDRs)**:
   - Ensure routes do not accidentally send traffic to wrong next hop or to internet.
5. Check **DNS**:
   - If using names instead of IPs, confirm name resolution is working.

Tools:

- `ping` (ICMP, if allowed).
- `Test-NetConnection` from Windows VM.
- `az network watcher` tools: IP flow verify, next hop, etc. (covered in Troubleshooting file).

---

## 10. Best Practices

1. **Plan address spaces from the beginning**  
   - Avoid overlapping ranges to keep peering options open.
2. **Use Hub-and-Spoke architecture** for multi‑app environments  
   - Centralize common services (firewall, DNS, VPN gateway) in hub.
3. **Use gateway transit** instead of multiple VPN gateways  
   - Saves cost and simplifies design.
4. **Limit who can create peerings**  
   - Peering connects networks at IP level; treat it as a high‑privilege operation.
5. **Enable “Allow forwarded traffic” only when needed**  
   - For NVA/firewall scenarios; otherwise leave it off.
6. **Monitor peering usage and costs** (especially global peering).

---

## 11. Exam Tips and Sample Questions

### Memory Hooks

- VNet peering = **Azure-to-Azure** private connectivity.
- Non-overlapping address spaces required.
- **No automatic transitive routing**.
- **Gateway transit**: hub (allow) ↔ spoke (use).
- Global VNet peering = cross-region.

### Sample Question 1

**Question:**  
You have two VNets in the same subscription and region:

- VNet1: 10.0.0.0/16
- VNet2: 10.0.1.0/24

You attempt to peer them, but the portal says this is not supported. Why?

**Answer:**  
Because the address spaces **overlap** (`10.0.1.0/24` is inside `10.0.0.0/16`). Peering requires **non-overlapping** address ranges.

### Sample Question 2

**Question:**  
You have a hub VNet with a VPN gateway to on‑premises. You want two spoke VNets to use that same gateway. What should you configure?

**Answer:**

- On hub VNet peering connections: enable **Allow gateway transit**.
- On each spoke VNet peering connection to hub: enable **Use remote gateways**.

### Sample Question 3

**Question:**  
VNetA is peered with VNetB, and VNetB is peered with VNetC. You want VMs in VNetA to reach VMs in VNetC without creating a new peering. What must you do?

**Explanation:**  
VNet peering is not transitive. You must either:

- Create a direct peering between VNetA and VNetC, or
- Use a hub-and-spoke design with an NVA/firewall and appropriate UDRs.

---

If you are comfortable with all the concepts in this file, you are ready for most VNet peering questions in AZ‑104.

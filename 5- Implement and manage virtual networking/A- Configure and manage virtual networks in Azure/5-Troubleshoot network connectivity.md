# Troubleshoot Network Connectivity in Azure

> AZ-104 Objective: **Troubleshoot network connectivity**

---

## 1. Troubleshooting Mindset

When something **cannot connect** in Azure (VM cannot reach internet, VM-to-VM fails, on‑prem to Azure fails), think in **layers**:

1. **IP configuration** (correct IP, subnet, gateway)
2. **Routing** (system routes, UDRs, VPN/ER)
3. **Network Security Groups (NSGs)** and firewalls
4. **Service-specific configuration** (load balancer rules, application gateway, etc.)
5. **DNS** (name resolution)
6. **Azure tools** (Network Watcher, metrics, logs)

For AZ-104, you must know **what to check first** and **which Azure tools to use**.

---

## 2. Common Connectivity Scenarios

### 2.1 VM Cannot Reach Internet

Possible causes:

- No public IP or NAT Gateway.
- NSG blocking outbound.
- Route table (UDR) sending `0.0.0.0/0` to wrong next hop.
- Azure Firewall or NVA blocking traffic.

### 2.2 VM-to-VM Connectivity Fails

Possible causes:

- VMs in different VNets with no peering.
- NSGs blocking traffic at subnet or NIC level.
- UDRs misrouting traffic.
- On-premises routing not aware of Azure subnets (for hybrid).

### 2.3 On‑premises to Azure Fails

Possible causes:

- VPN tunnel down.
- Wrong local/remote address ranges.
- Firewall blocking IPsec or application traffic.
- Route changes in Azure or on‑prem.
- BGP misconfig (for advanced scenarios).

---

## 3. First Checks: The Basics

### 3.1 Check VM Configuration

On the VM (Linux or Windows), verify:

- IP address and subnet mask.
- Default gateway.
- DNS server settings.

Azure automatically configures these via DHCP, but confirm they match expectations.

From inside VM, you can run:

- Windows: `ipconfig`, `route print`, `Test-NetConnection`.
- Linux: `ip addr`, `ip route`, `ping`, `curl`.

### 3.2 Check Azure Portal: NIC and Subnet

On the VM’s NIC:

- Is it attached to the correct **subnet**?
- Does subnet have the expected **NSG** and **route table**?
- Does NIC itself have an NSG?

**Key point:** NSGs can apply at both **subnet** and **NIC**.  

Traffic is allowed only if it passes **both**.

---

## 4. Troubleshooting with Network Security Groups (NSGs)

### 4.1 NSG Basics (Quick Reminder)

An NSG is a set of **allow/deny rules**.

Each rule has:

- Priority (lower number = higher priority)
- Direction (Inbound/Outbound)
- Source, Destination (IP, subnet, tag)
- Port
- Protocol (TCP/UDP/Any)
- Action (Allow/Deny)

### 4.2 Common NSG Problems

- Missing inbound rule (e.g., TCP/3389 not allowed for RDP).
- Too strict outbound rules (block HTTP/HTTPS).
- Deny rule with higher priority than allow rule.
- NSG associated with **wrong subnet** or NIC.

### 4.3 Tools: Effective Security Rules

In the Portal:

1. Go to **Network interface** for the VM.
2. Click **Effective security rules**.

Azure shows the **combined rules** from subnet NSG and NIC NSG.

Ask yourself:

- Is there an **Allow** rule for my traffic?
- Is there a **Deny** rule with higher priority?

**Exam tip:**  
> When a VM is unreachable, always consider NSGs and effective security rules.

---

## 5. Troubleshooting with Routes

### 5.1 Check Effective Routes

In the Portal:

1. Go to VM → **Networking** → Click NIC.
2. Click **Effective routes**.

You will see:

- System routes
- BGP routes (if VPN/ER)
- User-defined routes

Look for:

- Route to destination subnet or internet.
- Conflicting `0.0.0.0/0` route to wrong next hop.
- Overlapping prefixes.

### 5.2 Using Network Watcher: Next Hop

CLI example:

```bash
az network watcher show-next-hop \
  --resource-group rg-network-spoke1 \
  --vm vm-app-01 \
  --source-ip 10.1.1.4 \
  --destination-ip 8.8.8.8
```

This will tell you:

- Which route is applied.
- Next hop type (Internet, VirtualAppliance, etc.).
- Next hop IP (if applicable).

If next hop is **VirtualAppliance**, make sure that NVA is up, properly configured, and has its own routes.

---

## 6. Azure Network Watcher Tools (Very Important for Exam)

**Azure Network Watcher** is the central toolbox for network troubleshooting.

Enable it per region (usually happens automatically in modern portal).

### 6.1 IP Flow Verify

**What it does:** Checks if a packet from/to a VM would be allowed or denied by NSGs.

Example CLI:

```bash
az network watcher test-ip-flow \
  --resource-group rg-app-weu \
  --vm vm-web-01 \
  --direction Inbound \
  --local 10.10.1.4:3389 \
  --remote 203.0.113.5:50000 \
  --protocol TCP
```

Output shows:

- **Access**: Allow / Deny.
- Which **NSG rule** is responsible.

Use cases:

- RDP/SSH not working.
- Web ports not reachable.

**Exam tip:**  
> “IP flow verify” is specifically about **NSG rules** allowing/denying traffic.

### 6.2 Connection Troubleshoot (Connection Monitor / Connection Troubleshoot)

Tests connectivity between:

- VM → VM
- VM → Public IP or FQDN

Portal steps:

1. Open **Network Watcher**.
2. Select **Connection troubleshoot**.
3. Specify:
   - Source VM.
   - Destination (IP/FQDN and port).
4. Run test.

It tells you if connection succeeds and where it might be blocked.

### 6.3 NSG Diagnostics

- Helps analyze NSG configuration for a specific VM.
- In portal under Network Watcher for that VM or via CLI.

### 6.4 Packet Capture

You can capture packets from VM NIC using Network Watcher:

- Useful for deep troubleshooting (exam does not expect you to know packet formats, but know that **packet capture** exists).

### 6.5 VPN Troubleshoot (for gateways)

Network Watcher can troubleshoot VPN connections:

- Shows whether the tunnel is up/down.
- Gives logs and possible causes.

---

## 7. Connectivity Troubleshooting Examples

### 7.1 Example 1: VM Cannot Be RDP’d From Internet

**Scenario:**

- VM has a public IP.
- You try to RDP (3389) but connection fails.

**Checklist:**

1. Check VM is running.
2. Check NSGs:
   - Subnet NSG: Is there inbound rule allowing TCP/3389 from your IP or Any?
   - NIC NSG: Same check.
3. Check effective security rules.
4. Use **IP flow verify**:
   - Source: your public IP.
   - Destination: VM’s private IP:3389.
5. Verify no UDR forces traffic to unusual path.
6. Confirm local firewall on VM (Windows firewall) is not blocking.

**Most common cause:** NSG missing allow rule, or RDP is blocked at OS firewall.

### 7.2 Example 2: VM Cannot Reach Internet

**Scenario:**

- VM has **no public IP**.
- Subnet has no NAT Gateway, but default system routes exist.

This VM **cannot** reach internet unless:

- It is behind a load balancer with outbound rules, or
- A NAT Gateway is configured for the subnet, or
- There is a PIP on NIC.

**If NAT Gateway exists but still fails:**

- Check UDRs: maybe `0.0.0.0/0` points to Virtual appliance or Virtual network gateway instead of internet.
- Check NSG outbound rules.

### 7.3 Example 3: VM in Spoke1 Cannot Reach VM in Spoke2

Topology:

```text
VNet-hub (10.0.0.0/16)
  └─ Firewall NVA

VNet-spoke1 (10.1.0.0/16)
VNet-spoke2 (10.2.0.0/16)
```

- Spokes are peered with hub.
- Spoke-to-spoke traffic must go through firewall.

**Troubleshooting:**

1. Check VNet peering is **Connected** for all peerings.
2. Check UDRs in spokes:
   - Route to spoke2 (10.2.0.0/16) using **Virtual appliance** = firewall IP?
3. Check NSGs:
   - Allow traffic from/to firewall and other spokes.
4. Check firewall rules:
   - Does policy allow traffic between these networks?

**If using Network Watcher “Next hop” from VM in Spoke1 to VM in Spoke2:**

- It should show Next hop = VirtualAppliance (firewall IP).  
  If not, route table is wrong or missing.

---

## 8. DNS and Name Resolution Issues

Sometimes connectivity is fine, but **names** don’t resolve.

Symptoms:

- `ping 10.10.1.4` works, but `ping vm-web-01` fails.
- Applications using hostnames fail; IPs work.

Things to check:

1. DNS settings on VNet:
   - Using Azure-provided DNS or custom DNS (like on‑prem DNS).
2. If using custom DNS:
   - Is DNS server reachable over VPN/peering?
   - Are there proper records for Azure hostnames?

**Fix:**

- Correct DNS server IPs on VNet configuration.
- Ensure connectivity to DNS servers.
- Create appropriate A records.

**Exam tip:**  
> If FQDN doesn’t resolve but IP connectivity is okay → problem is DNS, not NSG/routing.

---

## 9. On‑Premises to Azure VPN Troubleshooting (High-Level)

Key items:

1. **Tunnel status** in Azure portal:
   - Go to VPN gateway → Connections → check Status = Connected.
2. Check logs:
   - Network Watcher VPN troubleshoot.
3. Match configurations:
   - Pre-shared key.
   - Local/remote networks (address prefixes).
   - Encryption algorithms (if using custom policies).

Common issues:

- Mismatch in address prefixes (Azure thinks on‑prem is 10.0.0.0/16 but real is 10.1.0.0/16).
- Overlapping address spaces (on‑prem and VNet use same range).
- Firewall blocking IPsec (UDP 500, 4500, ESP).

---

## 10. Systematic Troubleshooting Checklist

When you see an AZ‑104 question about connectivity, think in this order:

1. **Is basic connectivity possible?**
   - VM running? Correct IP? Same VNet or peering configured?
2. **Are NSGs allowing traffic?**
   - Check inbound and outbound on both sides.
   - Check effective security rules.
3. **Are routes correct?**
   - Any UDR overriding system route?
   - Effective routes show correct next hop?
4. **Any firewall/NVA in path?**
   - Are its rules and routes set to allow traffic?
5. **Is DNS okay?**
   - Does FQDN resolve to expected IP?
6. **Use Network Watcher tools**
   - IP flow verify → NSG.
   - Next hop → routing.
   - Connection troubleshoot → end-to-end path.
   - VPN troubleshoot → hybrid issues.

---

## 11. Exam Tips and Sample Questions

### Memory Hooks

- **IP flow verify** = NSG allow/deny decision.
- **Next hop** = which route is used.
- **Effective security rules** = combined NSG view.
- **Effective routes** = combined routing view.
- Think: **IP config → NSG → Routes → Firewalls → DNS**.

### Sample Question 1

**Question:**  
A VM in Azure cannot connect to an on‑premises server over VPN. Other VMs in the same VNet can. What is your first check?

**Best answer:**  
Check the **effective routes** and **NSGs** on the specific VM’s NIC to see if there is a UDR or NSG rule affecting only that subnet or NIC.

### Sample Question 2

**Question:**  
You run **IP flow verify** on a VM and the result is **Access: Deny** by rule `DenyAllInBound`. What should you do?

**Answer:**  
Add or modify an **NSG inbound rule** with higher priority to allow the required traffic (e.g., TCP/443), and ensure NSG is associated at subnet or NIC level.

### Sample Question 3

**Question:**  
You want to check which next hop is used for traffic from a VM to `8.8.8.8`. Which Network Watcher feature should you use?

**Answer:**  
Use **Next hop** (e.g., `az network watcher show-next-hop`).

### Sample Question 4

**Question:**  
A VM with no public IP needs outbound internet access. The subnet has a NAT Gateway, but outbound traffic still fails. What are two likely areas to check?

**Answer:**

1. Check **NSG outbound rules** for that subnet/NIC.
2. Check for **UDRs** that might be sending `0.0.0.0/0` to another next hop (like VPN gateway or virtual appliance) instead of using NAT Gateway.

---

If you understand these troubleshooting approaches and tools, you will be ready for most network connectivity questions in AZ‑104.

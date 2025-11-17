# Use Azure Network Watcher and Connection Monitor

## 1. Why Network Watcher matters

Even if your VMs and apps are healthy, users can still have problems if **network connectivity** is broken or slow.

**Azure Network Watcher** is a region‑based service that provides tools to:

- Monitor and troubleshoot network connectivity.
- Capture and analyze network traffic.
- Visualize topology and effective security rules.
- Enable flow logs and use Traffic Analytics.
- Continuously test connections with **Connection Monitor**.

For AZ‑104 you must know:

- What Network Watcher is.
- Its key features and when to use each.
- How **Connection Monitor** works and what problems it can solve.

---

## 2. Enabling Network Watcher (concept)

Conceptually:

- Network Watcher is enabled **per region** in your subscription.
- Once enabled in a region, its tools work for all supported resources in that region:
  - VMs, NICs
  - VNets and subnets
  - VPN gateways, Application Gateways, Load balancers, etc.

In the portal, Network Watcher is often already enabled automatically when you create network resources. If it is disabled, you can enable it from:

- **Monitor → Network / Network Watcher**, or
- **Search “Network Watcher”**, then enable in each region.

Exam perspective: **know that Network Watcher is the umbrella service for network troubleshooting tools**.

---

## 3. Key Network Watcher tools

### 3.1 Topology

**What it does**

- Shows a visual diagram of network resources in a resource group:
  - VNets, subnets
  - NICs, VMs
  - Load balancers, gateways, etc.
- Helps you understand how resources are connected.

**Use cases**

- Verify that resources are in the expected subnet and VNet.
- Quickly see if a VM is behind a load balancer or Application Gateway.
- Confirm peering links between VNets.

**Exam hint:**  
For questions like “You need a graphical view of the network architecture of a resource group” → use **Network Watcher Topology** or **Network insights**.

---

### 3.2 IP flow verify

**What it does**

- Simulates sending traffic from a VM’s NIC to a destination (IP/port) and tells you:
  - Whether the traffic is **allowed** or **denied**.
  - Which NSG rule (or default) is responsible.

**Inputs**

- Source:
  - VM / NIC (Network interface)
  - Source IP
  - Source port
- Destination IP and port
- Protocol (TCP/UDP)

**Outputs**

- **Allow** or **Deny**.
- NSG rule name and direction.
- NIC/subnet information.

**Use cases**

- Find out which NSG rule is blocking traffic.
- Validate that your firewall changes will allow required communication.

**Exam tip:**  
If the question is “Which Network Watcher tool shows whether traffic is blocked by an NSG rule and which rule?” → answer is **IP flow verify**.

---

### 3.3 Effective security rules

**What it does**

- Shows the **effective NSG rules** applied to a NIC or subnet.
- Combines:
  - NSG on subnet
  - NSG on network interface
  - Default platform rules

**Use cases**

- Troubleshoot access problems when multiple NSGs are applied.
- Verify that the final ruleset matches expectations.

**Difference vs IP flow verify**

- Effective rules: list of all rules that apply.
- IP flow verify: result for **one specific flow (5‑tuple)**.

---

### 3.4 Next hop

**What it does**

- Shows the **next hop** for traffic from a VM to a destination IP.
- Based on effective routes (system routes + user‑defined routes + BGP).

Possible next hops:

- Internet
- Virtual appliance (NVA)
- Virtual network
- VNet peering
- ExpressRoute, VPN Gateway
- None / Blackhole

**Use cases**

- Troubleshoot routing issues.
- Confirm that traffic goes through a firewall/NVA as expected.
- Find why traffic never reaches a destination (blackhole route).

---

### 3.5 Packet capture

**What it does**

- Captures packets from a VM’s network interface to a file (stored on disk or storage account).
- Can be started on‑demand or based on filters/time.

**Use cases**

- Deep troubleshooting with tools like Wireshark (e.g., protocol problems, handshake failures).
- Capturing only specific traffic (by IP, port, protocol) for analysis.

**Exam perspective**

- If the question mentions “capture packets to analyze with external tools” → answer is **Packet capture**.

---

### 3.6 NSG flow logs and Traffic Analytics

**NSG flow logs**

- Logs connection flows (source/destination IP, port, protocol, allowed/denied).
- Stored in a **storage account**; can be sent to **Log Analytics**.
- Version 2 provides richer JSON data.
- Requires NSG and Network Watcher configuration.

**Traffic Analytics**

- Built on top of NSG flow logs.
- Provides ready‑made dashboards:
  - Top talkers (IP pairs with most traffic).
  - Allowed vs denied flows.
  - Traffic by protocol/port/location.
  - Threat intelligence insights (e.g., communication with malicious IPs).

**Use cases**

- Security monitoring and investigations.
- Capacity planning and network optimization.

**Exam hint:**  
If the scenario is “analyze which IP addresses cause the most denied flows across many NSGs” → think **NSG flow logs + Traffic Analytics**.

---

## 4. Connection Monitor – continuous connectivity tests

**Connection Monitor** is part of Network Watcher and provides *continuous, end‑to‑end monitoring* of network connectivity.

### 4.1 What Connection Monitor does

- Periodically tests connectivity between:

  - Azure VMs
  - On‑premises machines (via agent)
  - URLs, FQDNs, IPs, or other endpoints

- Measures:
  - Reachability (success/failure).
  - Round‑trip time (latency).
  - Packet loss (depending on protocol).
  - Path/hops (for some scenarios).

- Writes results to logs and surfaces insights and alerts.

### 4.2 Key concepts

- **Connection Monitor resource**
  - Logical container for tests.

- **Test groups**
  - A set of sources and destinations with shared test configuration.

- **Endpoints**
  - Sources: VM, on‑prem host (via agent), IP, subnet.
  - Destinations: IP, FQDN, URL, Azure resource.

- **Test configuration**
  - Protocol: TCP, ICMP, HTTP(s).
  - Port (for TCP).
  - Test frequency/interval.
  - Thresholds for success/latency.

### 4.3 Example: monitor branch office to Azure VM

Goal: ensure branch office server can always reach an Azure VM over TCP 443.

1. Install Network Watcher/Connection Monitor agent on the branch server (or use another Azure VM as source).
2. Create a **Connection Monitor** instance:
   - Source endpoint: On‑prem host.
   - Destination endpoint: VM private IP or FQDN.
   - Protocol: TCP.
   - Port: 443.
   - Test frequency: e.g., every 1 minute.
3. Configure alerts on:
   - Connection failures.
   - Latency above certain threshold (e.g., > 200 ms).

**Result:** you see uptime, latency trends, and get alerts when connectivity is broken or slow.

### 4.4 Example: monitor website availability

Goal: ensure public web app (`https://contoso.com`) is reachable.

1. Create Connection Monitor with:
   - Source: one or more Azure VMs or test agents.
   - Destination: `https://contoso.com`.
   - Protocol: HTTP/HTTPS.
2. Monitor:
   - Success/failure rate.
   - Response times.

This is similar in spirit to Application Insights availability tests but provided at network/Network Watcher level.

---

## 5. When to use which Network Watcher feature

### 5.1 Quick decision table

| Problem / Requirement                                           | Tool to use                                      |
|-----------------------------------------------------------------|--------------------------------------------------|
| See network diagram of a resource group                         | **Topology**                                     |
| Check if NSG is blocking specific flow (source/dest/port)      | **IP flow verify**                               |
| See all firewall/NSG rules in effect on a NIC or subnet         | **Effective security rules**                     |
| Check where traffic is routed (Internet, NVA, blackhole)        | **Next hop**                                     |
| Capture packets from a VM for deep analysis                     | **Packet capture**                               |
| Analyze allowed/denied flows across NSGs                        | **NSG flow logs + Traffic Analytics**            |
| Continuously test connectivity between endpoints                | **Connection Monitor**                           |
| Troubleshoot intermittent VPN connectivity                      | **Connection Monitor + Network insights**        |

### 5.2 Combining tools

Real troubleshooting often uses **several** tools:

Example – client cannot reach VM over port 1433 (SQL):

1. **Ping / basic checks** (connectivity).
2. **IP flow verify**:
   - Source: client VM or jump host.
   - Destination: SQL VM IP and port 1433.
   - If Deny → fix NSG rule.
3. If NSGs allow:
   - Use **Next hop** to ensure traffic goes to correct network path (no blackhole).
4. If connectivity is flaky over time:
   - Configure **Connection Monitor** between source and target to track success/latency over several hours.

---

## 6. Exam‑style scenarios

### Scenario 1 – Identify which NSG rule blocks a connection

> A VM can’t connect to a database on another VM. You must find which NSG rule is causing the block.

Best answer:

- Use **Network Watcher → IP flow verify** for that VM’s NIC and destination IP/port.
- It will show whether the flow is allowed or denied and which rule applied.

### Scenario 2 – Monitor hybrid connectivity over time

> You have a site‑to‑site VPN from on‑prem to Azure. You want to be alerted if round‑trip latency exceeds 200 ms or if the link drops.

Tools:

- **Connection Monitor** to continuously test from on‑prem host to Azure VM or service.
- Configure alerts based on Connection Monitor results (log/metric alerts).
- Optionally, use **Network insights** to monitor VPN connection status.

### Scenario 3 – Get a high‑level view of network resources and health

> The network team wants a dashboard of all VNets, gateways, and load balancers with their health status.

Answer:

- Use **Azure Monitor Network insights** (or **Network Watcher** overview) to get topology and health.
- Configure alerts on important metrics (VPN connection state, load balancer availability, etc.).

### Scenario 4 – Analyze which traffic is most often denied

> Security needs to know which IP addresses or ports are being denied most by NSGs across the environment.

Answer:

1. Enable **NSG flow logs** in Network Watcher and send them to a storage account and/or Log Analytics workspace.
2. Enable **Traffic Analytics** for graphical summary.
3. Run KQL queries or use Traffic Analytics dashboard to see top denied flows.

### Scenario 5 – Capture HTTP traffic for debugging

> Developers claim a request never reaches the web server VM, but they want packet details.

Answer:

- Use **Network Watcher → Packet capture** on the VM’s NIC to capture port 80/443 traffic.
- Download capture file and analyze with Wireshark/Fiddler.

---

## 7. Summary

**Azure Network Watcher** is your toolbox for network monitoring and troubleshooting:

- **Topology** – visual map of network resources.
- **IP flow verify** – checks if a specific flow is allowed/denied by NSGs.
- **Effective security rules** – final NSG rules applied to NIC/subnet.
- **Next hop** – reveals routing path and blackholes.
- **Packet capture** – low‑level packet capture for deep analysis.
- **NSG flow logs + Traffic Analytics** – rich analytics of network flows.

**Connection Monitor** (part of Network Watcher) provides **continuous, end‑to‑end connectivity monitoring** between Azure and on‑prem or across regions, with insights on reachability and latency.

For AZ‑104, focus on:

- Knowing **which tool to choose** for a given network problem.
- Understanding how to enable and read basic outputs.
- Combining Insights (Network, VM, Storage) with Network Watcher tools to solve performance and connectivity issues.

Mastering these concepts will help you confidently answer exam questions related to “Use Azure Network Watcher and Connection Monitor” and real‑world troubleshooting scenarios.

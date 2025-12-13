# Configure and interpret monitoring of VMs, storage accounts, and networks using Azure Monitor Insights

## 1. What are Azure Monitor “Insights”?

**Azure Monitor Insights** are ready‑made, opinionated views for specific workloads.  
They sit on top of Azure Monitor metrics and logs and give you:

- Dashboards and charts that are already wired to the right data.
- Health summaries across many resources.
- Deep‑dive views (e.g., VM performance, network topology, storage latency).

For AZ‑104, focus on three main areas:

1. **VM Insights** – Monitoring virtual machines and VM scale sets.
2. **Storage monitoring** – Insights for storage accounts.
3. **Network insights** – Health and topology for network resources.

You should know:

- How to **enable** them.
- What data they **collect**.
- How to **interpret** the main charts and health signals.
- Which **tool** to pick in exam scenarios.

---

## 2. VM Insights

### 2.1 Purpose

VM Insights gives you:

- A single place to see performance and health of many VMs.
- Detailed view for a single VM: CPU, memory, disk, network.
- Dependency maps (which processes talk to which endpoints).
- Integration with log queries, alerts, and workbooks.

### 2.2 How VM Insights works (high level)

1. You **enable** VM Insights on a VM or VM scale set:
   - From **VM → Insights → Enable**.
   - Or from **Monitor → Virtual machines (Insights)**.
2. Azure installs/uses **Azure Monitor Agent (AMA)** on the VM.
3. A **Data Collection Rule (DCR)** defines what to collect and to which **Log Analytics workspace**.
4. Data is stored in tables like:
   - `InsightsMetrics`
   - `Perf`
   - `Heartbeat`
5. The **VM Insights blades** read from these tables and show performance charts and maps.

**Exam hint:**  
If the question says “You must view performance and map dependencies for multiple VMs in one place” → answer is **VM Insights**.

### 2.3 Enabling VM Insights (portal flow)

For a single VM:

1. Go to the VM → **Insights**.
2. Click **Enable** (if not already enabled).
3. Choose:
   - **Log Analytics workspace**.
   - **Data collection rule** (or create a new one).
4. Click **Enable** and wait for data to appear (a few minutes).

For many VMs:

- Use **Monitor → Virtual machines** (Insights view) to enable monitoring at scale.
- Or use **Policy** or **ARM/Bicep** to deploy AMA + DCR.

---

### 2.4 VM Insights views and how to read them

#### a) Performance

Shows metrics like:

- CPU utilization (percentage).
- Available memory or memory usage.
- Disk IOPS, throughput, queue length.
- Network In/Out.

**Interpretation examples:**

- CPU consistently > 80–90% → VM is under heavy load.  
  - Fix: scale up VM size, optimize app, or scale out.
- Memory usage near 100% or very low available memory → risk of paging and poor performance.
- Disk IOPS high + high disk latency or queue length → disk is a bottleneck.  
  - Fix: move to Premium/Ultra disks, increase disk count, optimize access patterns.
- Network In/Out unexpectedly high → possible data exfiltration, heavy sync, or DDOS (with other symptoms).

#### b) Map (dependencies)

Shows:

- Processes running on the VM.
- Connections between VMs and external endpoints.
- Ports used and dependent services.

Use cases:

- See which services talk to a database VM.
- Understand impact of shutting down a VM.
- Identify unexpected external connections.

**Exam hint:**  
If you need “dependency map” or “which services call my VM”, the answer is **VM Insights map**.

#### c) Health & Alerts

- Shows overall health status (healthy / warning / critical) based on metrics and agent status.
- Integrates with alert rules (e.g., CPU, memory thresholds).

---

## 3. Storage account monitoring (Azure Monitor for Storage)

### 3.1 What it provides

Azure Monitor exposes storage account metrics and logs via:

- **Metrics / Insights** view under the storage account.
- Optional **resource logs** (via diagnostic settings).
- Workbooks and templates for deeper analysis.

Typical metrics per storage service (Blob, File, Queue, Table):

- `Availability` (%)
- `Transactions`
- `Ingress` / `Egress` bytes
- `SuccessE2ELatency` (end‑to‑end latency)
- `SuccessServerLatency`
- `ClientOtherError`, `ServerOtherError`
- Throttling metrics (e.g., `ThrottlingError`)

### 3.2 Enabling and viewing storage monitoring

1. In the portal, open the **Storage account**.
2. Use:
   - **Monitoring → Metrics** – to chart metrics.
   - **Monitoring → Insights** – for pre‑built dashboards (if available).
   - **Monitoring → Diagnostic settings** – to send logs to workspace/storage/Event Hub.

For exam purposes:

- Know that **no special agent is needed** – metrics are platform metrics.
- Logs (e.g., detailed transaction logs) require **diagnostic settings**.

### 3.3 Interpreting common charts

**Latency charts**

- `SuccessE2ELatency`: overall response time from client perspective.
- `SuccessServerLatency`: time spent inside the storage service.

If:
- Server latency is low, but end‑to‑end latency is high
  - Possible network or client‑side issues.
- Both are high
  - Storage account or underlying infrastructure bottleneck.

**Availability**

- Shows percentage of successful requests.
- A drop can indicate service issues, network problems, or misconfiguration (e.g., wrong keys, firewall rules).

**Transactions and errors**

- `Transactions` rising normally → healthy usage growth.
- Sudden drop to 0 → clients stopped sending requests or are failing early.
- High error metrics (`ServerOtherError`, `ClientOtherError`, 4xx/5xx categories) → misconfig or service problems.

### 3.4 Logs for deeper analysis

With **resource logs** enabled, you can:

- See detailed records of each request (operation type, response code, authentication).
- Identify patterns:
  - Who is hitting the account the most.
  - Which operations are failing and from which IPs.
- Use KQL queries to slice per container, per operation, etc.

Scenario:

> “Investigate why some blob downloads are failing.”

Steps:

1. Ensure **diagnostic settings** are sending logs to a Log Analytics workspace.
2. Query logs for:
   - Operation type = `GetBlob`.
   - Response code (e.g., 403, 404, 500).
3. Check correlation with metrics charts (latency, availability).

---

## 4. Network insights (Azure Monitor for Networks)

### 4.1 Purpose

**Network insights** give a **central view** of your network health:

- Virtual networks and peerings.
- Load balancers and Application Gateways.
- VPN gateways and connections.
- ExpressRoute circuits.
- NSGs and traffic analytics.

It leverages:

- Platform metrics (availability, throughput, errors).
- Network Watcher tools (Connection Monitor, NSG flow logs, etc.).

### 4.2 Accessing network insights

From Azure portal:

- Go to **Monitor → Network** or **Network Insights** (label can vary slightly).
- Or open **Network Watcher** and use its insights/overview.

You typically see:

- Topology maps showing relationships between VNets, subnets, gateways, and on‑prem connections.
- Health indicators (healthy, degraded, unreachable).
- Aggregated metrics and issues.

### 4.3 Typical things you can see

- **VPN Gateway / Connection health**
  - Tunnel up/down status.
  - Bandwidth usage (ingress/egress).
  - Packet loss or latency.

- **Application Gateway**
  - Current connections.
  - Total and failed requests.
  - Backend pool health.

- **Load Balancer**
  - Data path availability.
  - Number of flows.
  - SNAT port usage (important for outbound connections).

- **ExpressRoute**
  - Circuit state.
  - Throughput and errors.

### 4.4 Interpreting common scenarios

**Scenario: VPN connection down**

- In Network insights:
  - VPN connection marked as **Disconnected/Not connected**.
  - Metrics show 0 traffic, possible error codes.

Likely actions:
- Check local VPN device.
- Use **Connection Monitor** or **VPN diagnostics** for deeper troubleshooting.

**Scenario: Load balancer SNAT port exhaustion**

- SNAT port usage metric near maximum.
- Symptoms: outbound connections fail or are reset.

Fixes:
- Use public IP per instance (Standard LB).
- Change architecture (e.g., use NAT gateway).
- Increase number of backend instances.

**Scenario: Application Gateway errors**

- High failed requests or 5xx from backend.
- Backend pool health status degraded.

Fixes:
- Check backend app health.
- Verify health probes and routing rules.

---

## 5. Putting it together – choosing the right insight

### 5.1 When to use VM Insights

Use VM Insights when you need:

- Performance overview for many VMs.
- Deep‑dive into CPU, memory, disk, and network for a single VM.
- Dependency map of a VM’s connections.
- Alerting based on VM performance collected by AMA.

Example exam question patterns:

- “You must identify which VM in a resource group has the highest CPU usage.”
- “You must see inbound and outbound connections for a VM and which processes are listening on which ports.”

Answer: **Enable and use VM Insights**.

### 5.2 When to use storage monitoring

Use storage monitoring when you need:

- Latency and availability metrics for storage accounts.
- Transactions and error rates per storage service (Blob, File, Queue).
- Long‑term audit of access operations.

Example exam questions:

- “Users report slow file access from Azure Files.”
  - Check **latency metrics** and **availability** for the File share.
- “Security team needs full logs of who accessed a blob container.”
  - Enable **diagnostic settings** and use **Log Analytics** queries.

### 5.3 When to use network insights

Use network insights when you need:

- A centralized view of your network environment (VNets, GW, LB, App Gateway).
- Health state and metrics for VPN, ExpressRoute, load balancers.
- Lightweight topology view and integration with Network Watcher tools.

Example exam questions:

- “You must monitor whether VPN connections are up and notify admins when they go down.”
  - Use **Network insights** + relevant **alerts** (VPN connection metrics / resource health).
- “You need a topology view showing VNets, peerings, and gateways.”
  - Use **Network insights** or **Network Watcher topology**.

---

## 6. Example end‑to‑end scenarios

### Scenario 1 – VM performance issue

> Users complain that an application on a VM is slow.

1. **VM Insights → Performance**
   - Check CPU, memory, disk IOPS and latency.
2. **VM Insights → Map**
   - See which other services the VM depends on (database, APIs).
3. **Logs (Perf/InsightsMetrics)**
   - If needed, run KQL to analyze longer term trends.
4. **Alerts**
   - If you identify a threshold, configure a metric or log alert.

### Scenario 2 – Storage latency spikes

> Application that uses Blob storage is slow at random times.

1. **Storage account → Metrics/Insights**
   - Check `SuccessE2ELatency` and `SuccessServerLatency` over the problematic time.
   - See if there are spikes correlated with high `Transactions`.
2. **Diagnostic logs (if enabled)**
   - Use KQL to see which containers/operations/users were involved.
3. **Capacity & throttling**
   - Check for throttling metrics or capacity limits.

### Scenario 3 – Intermittent connectivity between on‑prem and Azure

1. **Network insights**
   - Check VPN connection health and metrics.
2. **Connection Monitor** (via Network Watcher)
   - Configure continuous tests from on‑prem to Azure.
3. **Log Analytics**
   - Analyze Connection Monitor logs for packet loss and latency.

---

## 7. Summary

Azure Monitor Insights simplify monitoring for complex resources:

- **VM Insights** – install/enable AMA + DCR and:
  - See performance charts (CPU, memory, disk, network).
  - Use dependency maps to understand traffic flows.
  - Base investigations and alerts on `InsightsMetrics`, `Perf`, `Heartbeat`.

- **Storage monitoring** – no agent needed:
  - Use metrics and logs to track latency, availability, transactions, and errors.
  - Enable diagnostic settings for detailed access and audit logs.

- **Network insights** – powered by platform metrics and Network Watcher:
  - Show network topology and health for VPN, ExpressRoute, load balancers, gateways.
  - Integrate with Connection Monitor and NSG flow logs for deeper analysis.

For AZ‑104, practice reading the Insights blades in the portal, understand what each chart means, and be able to choose **which insight/tool** to use when an exam scenario describes a performance or connectivity problem.

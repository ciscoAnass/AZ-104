# Interpret metrics in Azure Monitor

## 1. Big picture: what are metrics?

**Azure Monitor metrics** are numeric values that describe how a resource behaves over time.  
Think of them as a series of measurements taken every few seconds or minutes.

- Example metrics:
  - VM CPU percentage
  - Storage account latency
  - Number of HTTP requests on an App Service
  - Network bytes in/out

### Metrics vs Logs (very important for the exam)

| Feature          | Metrics                                           | Logs                                                          |
|-----------------|---------------------------------------------------|---------------------------------------------------------------|
| Data type       | Numbers (time series)                             | Semi‑structured records (rows, columns)                      |
| Typical use     | Performance, utilization, near real‑time alerts   | Detailed troubleshooting, auditing, security investigations  |
| Storage         | Metrics store (platform metrics, custom metrics)  | Log Analytics workspace / storage / Event Hub                |
| Query language  | Simple UI (Metrics explorer) or REST/SDK          | Kusto Query Language (KQL)                                    |
| Granularity     | Per minute (typical)                              | Depends on data source                                       |

**Exam tip:**  
If the question talks about:
- *“Quick performance overview”*, *“real‑time trend chart”*, *“CPU threshold alert”* → **Metrics**.  
- *“Search all failed sign‑ins”*, *“which NSG rule blocked traffic”*, *“detailed query with filters”* → **Logs**.

---

## 2. Key concepts: how Azure Monitor metrics are organized

### 2.1 Metric namespace

A **metric namespace** is a logical group of metrics for a resource type.

- Example (VM):
  - `Virtual Machine Host` (CPU, disk, network metrics)
  - `Guest (classic)` or AMA/Insights-related namespaces for guest metrics
- Example (Storage account):
  - `Blob`
  - `File`
  - `Table`
  - `Queue`

In Metrics explorer you often first choose:
1. **Scope** (the resource)
2. **Metric namespace**
3. **Metric**

### 2.2 Metric types

1. **Platform metrics**
   - Built‑in metrics collected automatically by Azure.
   - Example: VM `Percentage CPU`, Storage `Transactions`, Load balancer `SNATConnectionCount`.

2. **Custom metrics**
   - Your own metrics sent from apps, scripts, or agents.
   - Example: `OrdersPerMinute`, `LoginFailures`.

3. **Application metrics (App Insights)**
   - Application performance metrics such as `server response time`, `requests rate`, `dependency duration`.

For AZ‑104 you mainly need to recognize **platform metrics**, but be aware others exist.

### 2.3 Time series

Each metric is a **time series**:

- X‑axis = time
- Y‑axis = metric value
- Data points are grouped into **time buckets** (1 min, 5 min, 1 hour, etc.)

Azure stores metrics for a limited time (for standard platform/custom metrics this is around **93 days** by default).  
You typically choose a **time range** in Metrics explorer like last 1 hour, 24 hours, 7 days, etc.

### 2.4 Dimensions

Some metrics have **dimensions** – extra properties that let you break down the metric.

Examples:
- VM disk metric with dimension **`Disk`** (C:, D:, etc.)
- HTTP requests metric with dimension **`ResponseCode`** (200, 404, 500)
- Network metric with dimension **`Direction`** (Inbound, Outbound)

In Metrics explorer you can:
- **Filter** by dimension value (e.g., only disk C:)
- **Split** by dimension value to show multiple lines (one per disk, one per response code, etc.)

**Exam tip:**  
If you see “per disk”, “per response code”, or “per status”, think **dimensions** and **split by dimension**.

---

## 3. Using Metrics explorer (portal)

### 3.1 Steps to create a metric chart

1. In the Azure portal, open **Monitor** → **Metrics**.
2. Select the **Scope** (resource, resource group, or subscription).
3. Choose the **Metric namespace**.
4. Select a **Metric** (e.g., Percentage CPU).
5. Choose **Aggregation** (Average, Max, Min, Sum, Count).
6. Set **Time range** and **Time granularity** (auto or fixed).
7. (Optional) Use **Filters** and **Splitting** by dimensions.
8. (Optional) Change **chart type** (line, area, bar) and **pin to dashboard**.

### 3.2 Aggregations (super important)

Azure collects multiple raw data points per time bucket and then aggregates them.

Common aggregations:

- **Average** – typical for utilization (CPU %, latency).
- **Maximum** – good for spikes (peak CPU, peak latency).
- **Minimum** – rarely used alone, but can show dips.
- **Sum** – used for counters (total requests, total errors).
- **Count** – number of data points in the period.
- **Percentile (P90/P95/P99)** – shows how “bad” the worst requests are without being affected by extreme outliers.

**Example 1 – CPU**
- Metric: `Percentage CPU`
- Aggregation: **Average**
- If Average CPU is > 80% for 5 minutes → possible overload.

**Example 2 – HTTP errors**
- Metric: `Requests`
- Aggregation: **Sum**
- Dimension: `ResponseCode`
- Filter: `ResponseCode = 500` → total number of server errors.

**Exam hint:**  
If the question says **“total number of operations”** → use **Sum**.  
If it says **“utilization”** or **“usage over time”** → use **Average**.

### 3.3 Time granularity

- **Smaller granularity** (1 min):
  - More detail, more spiky charts.
  - Better for troubleshooting short incidents.

- **Larger granularity** (1h, 6h):
  - Smoother chart, easier to see trends.
  - Useful for capacity planning.

Azure can automatically choose the granularity based on the time range, or you can force it.

---

## 4. Common metrics by resource type

### 4.1 Virtual machines (IaaS)

Key metrics for VMs:

- **Percentage CPU** – overall CPU usage of the VM.
- **Available Memory** (guest metric) – if very low → memory pressure.
- **Disk Read/Write Operations/sec** – IOPS. High values mean heavy disk usage.
- **Disk Read/Write Bytes/sec** – throughput; high values mean heavy data transfer.
- **Network In / Out** – amount of data in/out of the NIC.
- **CPU Credits Remaining / Consumed** – for burstable VM sizes (B‑series).

**How to interpret:**

- High CPU (> 80–90% for a long time)  
  → scale up (bigger VM) or optimize application.
- High Disk IOPS + high disk queue length  
  → disk is a bottleneck; consider Premium SSD / Ultra Disk or more disks.
- No recent `Heartbeat` (log metric) + flat CPU/Network  
  → VM may be stopped or unreachable.

### 4.2 Storage accounts

Important metrics:

- **Transactions** – number of operations (read, write, list, delete).
- **Ingress / Egress** – amount of data in/out.
- **Success E2E Latency / Server Latency** – performance from client and from service side.
- **Availability** – percentage of successful requests.
- **Throttling / Server Errors (4xx/5xx)** – problems or limits reached.
- **Used capacity** – space used by data.

**Interpretation examples:**

- High latency and client errors → investigate network or client code.
- High throttling → hitting request limits; consider partitioning, premium SKU, or design changes.
- Decreasing availability → possible service or configuration issues.

### 4.3 Network resources

Examples:

- **Load balancer** – `Data Path Availability`, `SNATConnectionCount`, `ByteCount`.
- **Application Gateway** – `CurrentConnections`, `FailedRequests`, `TotalRequests`.
- **VPN Gateway / Connections** – `TunnelIngressBytes`, `TunnelEgressBytes`, `TunnelDown`.

Use these to answer questions like:
- “Is the VPN tunnel up?”
- “Is the load balancer dropping connections?”
- “Is traffic evenly distributed?”

---

## 5. Working with multi‑resource and dimensioned metrics

### 5.1 Multi‑resource metrics

In Metrics explorer you can select:
- One resource
- Multiple resources (for some metric types)
- Even a **resource group** or **subscription** as scope

Example:
- You want to see average CPU for all web servers.
- Scope = Resource group (RG‑WebServers)
- Metric = `Percentage CPU`
- Split by = `Resource` (one line per VM).

This is helpful for finding:
- A single VM that is overloaded compared to others.
- Patterns across many resources.

### 5.2 Splitting by dimensions

For metrics with dimensions:

- Example: Storage account `Transactions` with dimension `ResponseType`.
- By using **Split by ResponseType**, you see:
  - Line for Success
  - Line for ClientError
  - Line for ServerError

This makes it easy to detect:
- Increase in errors
- Specific disks or endpoints that are slow or failing

---

## 6. Using metrics for alerting (short overview)

You typically combine metrics with **metric alert rules**:

- Condition example:
  - If `Percentage CPU` **Average** > 80%
  - For **5 minutes**
- Evaluation frequency:
  - Every 1, 5, or 15 minutes.
- Action:
  - Trigger an **Action group** (email, SMS, webhook, etc.).

You will study alerts deeply in a separate file, but for now remember:

> **Metrics → near real‑time numeric data → metric alerts use that data.**

---

## 7. Typical exam scenarios and how to think

### Scenario 1 – Performance dashboard

> You need to see CPU, memory, and disk performance for a VM over the last 24 hours.

- Tool: **Azure Monitor → Metrics** or **VM → Insights / Metrics**.
- Data type: **Metrics**, not logs.
- Steps:
  - Choose VM scope.
  - Plot `Percentage CPU`, `Available Memory`, `Disk Read/Write Operations/sec`.
  - Choose **Average** aggregation.

### Scenario 2 – Which disk is slow?

> One VM has slow performance. You want to know which disk is causing high latency.

- Metric: `Disk Read/Write Latency` or related disk metric with **Disk** dimension.
- In Metrics explorer:
  - Split by **Disk**.
  - Look for the disk with highest latency / IOPS.

### Scenario 3 – Count total storage transactions

> The storage team wants to see total number of blob operations per day.

- Metric: `Transactions` (Blob namespace).
- Aggregation: **Sum**.
- Granularity: 1 hour or 1 day.
- Use metrics explorer to create the chart and export or pin to dashboard.

### Scenario 4 – Spiky charts vs smooth charts

> You see a CPU chart with very spiky lines. Management wants a smoother view.

- Increase **time granularity** (e.g., from 1 min to 1 hour).
- Or use **longer time range**.

---

## 8. Summary

- **Metrics** are numeric time series, best for performance, capacity, and near real‑time alerting.
- They are organized by **namespace**, **metric**, and sometimes **dimensions**.
- Use **Metrics explorer** to:
  - Select scope, metric, aggregation, time range.
  - Filter and split by dimensions.
  - Compare multiple metrics and resources.
- Know common metrics for **VMs**, **storage accounts**, and **network resources**.
- Understand how to interpret charts and choose the right **aggregation**.
- Recognize when to use **metrics vs logs** in exam questions.

If you are comfortable reading metric charts and explaining what is happening to a VM, storage account, or network resource over time, you are in a good position for this part of AZ‑104.

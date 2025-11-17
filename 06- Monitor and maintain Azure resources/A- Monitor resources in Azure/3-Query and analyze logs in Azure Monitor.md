# Query and analyze logs in Azure Monitor

## 1. Where log queries live

Azure Monitor logs are stored in **Log Analytics workspaces**.  
To work with them, you use the **Logs** experience in the Azure portal:

- You can open Logs from:
  - **Monitor → Logs**
  - A specific workspace → **Logs**
  - A resource → **Logs** (pre‑selects the workspace and scope)

Queries use **Kusto Query Language (KQL)**.  
For AZ‑104 you are not expected to be a KQL expert, but you must:

- Understand basic query structure.
- Read and interpret simple queries.
- Know how to filter, summarize, and visualize results.

---

## 2. Basic KQL structure

A KQL query is **table‑first** and then a series of **operators** joined by pipes `|`.

General pattern:

```kusto
TableName
| where ...
| project ...
| summarize ...
| order by ...
```

### 2.1 Common tables (exam‑relevant)

- `AzureActivity` – Subscription Activity log (operations, admin actions).
- `Heartbeat` – Guest heartbeats from VMs/servers (via AMA/agent).
- `Perf` – Performance counters (CPU, memory, disk, network).
- `InsightsMetrics` – Metrics from VM Insights and other insights.
- `AzureDiagnostics` or Resource‑specific tables – Service resource logs.
- `SigninLogs`, `AuditLogs` – Microsoft Entra ID sign‑in and audit logs (if sent to workspace).
- `SecurityEvent` – Windows security events (if collected).

---

## 3. Time filtering

Almost all log tables have a **TimeGenerated** column.

There are two main ways to filter by time:

1. Use the **time picker** in the portal (top‑right of Logs window).
2. Use `where TimeGenerated` in the query:

```kusto
AzureActivity
| where TimeGenerated > ago(24h)
```

**Common time helpers:**

- `ago(1h)` – last 1 hour
- `ago(24h)` – last 24 hours
- `ago(7d)` – last 7 days

**Exam hint:**  
If a query doesn’t show recent data, check if the time range is too small/too old.

---

## 4. Essential KQL operators

### 4.1 `where` – filter rows

```kusto
AzureActivity
| where TimeGenerated > ago(24h)
| where ActivityStatus == "Failed"
```

- Keeps only rows that match the condition.
- You can chain multiple `where` statements.

### 4.2 `project` – select/rename columns

```kusto
AzureActivity
| where TimeGenerated > ago(24h)
| project TimeGenerated, OperationName, ResourceGroup, Caller
```

- Pick only the columns you care about.
- You can also rename:

```kusto
| project TimeGenerated, OperationName, RG = ResourceGroup, User = Caller
```

### 4.3 `summarize` – aggregate (group by)

```kusto
AzureActivity
| where TimeGenerated > ago(24h)
| summarize Count = count() by ActivityStatus
```

- Aggregates rows and produces one row per group.
- Common aggregation functions:
  - `count()` – number of rows.
  - `avg()` – average value.
  - `min()`, `max()`.
  - `sum()`.
  - `percentile(Value, 95)` or `percentiles(Value, 50, 95, 99)`.

---

### 4.4 `order by` (or `sort`) – sort rows

```kusto
AzureActivity
| where TimeGenerated > ago(24h)
| summarize Count = count() by Caller
| order by Count desc
```

- Sorts results descending or ascending.

### 4.5 `take` / `limit` / `top`

```kusto
AzureActivity
| where TimeGenerated > ago(24h)
| take 10
```

```kusto
AzureActivity
| where TimeGenerated > ago(24h)
| top 5 by TimeGenerated desc
```

---

### 4.6 `extend` – add calculated columns

```kusto
Perf
| where ObjectName == "Processor" and CounterName == "% Processor Time"
| extend CPUPercent = CounterValue
```

You can calculate new values, combine strings, or pre‑format data.

---

## 5. Examples you should understand

### 5.1 List failed operations in last 24h

```kusto
AzureActivity
| where TimeGenerated > ago(24h)
| where ActivityStatus == "Failed"
| project TimeGenerated, OperationName, ResourceGroup, Caller, StatusCode
| order by TimeGenerated desc
```

What this does:

- Looks at Activity log (`AzureActivity`).
- Keeps only last 24 hours.
- Filters to failed operations.
- Shows selected columns.
- Sorts newest first.

**Use case:** find which operations are failing and who attempted them.

---

### 5.2 Find VMs with high CPU

Assuming performance data is in `Perf`:

```kusto
Perf
| where TimeGenerated > ago(1h)
| where ObjectName == "Processor" and CounterName == "% Processor Time"
| summarize AvgCPU = avg(CounterValue) by Computer
| where AvgCPU > 80
| order by AvgCPU desc
```

Explanation:

- Filter to last 1h.
- Filter to CPU performance counter.
- Compute average CPU for each computer.
- Keep only VMs with AvgCPU > 80%.
- Sort by highest CPU.

**Exam hint:**  
Understand that `summarize ... by Computer` groups data by VM and `avg()` calculates the average CPU.

---

### 5.3 Check which VMs stopped sending heartbeat

```kusto
Heartbeat
| summarize LastHeartbeat = max(TimeGenerated) by Computer
| where LastHeartbeat < ago(10m)
```

Interpretation:

- For each VM (Computer), find the last heartbeat time.
- If it is older than 10 minutes, the VM may be:
  - Stopped
  - Disconnected
  - Agent not working

---

### 5.4 Count NSG denies (if NSG flow logs are in workspace)

Table name can vary (for example, `AzureDiagnostics` or a flow‑log specific table):

```kusto
AzureDiagnostics
| where TimeGenerated > ago(1h)
| where Category == "NetworkSecurityGroupFlowEvent"
| where action_s == "D"  // D = Deny, A = Allow
| summarize Denies = count() by SrcIp_s, DestIp_s, DestPort_d
| order by Denies desc
```

Use case: see which traffic is being blocked most often.

---

## 6. Visualizing results

KQL has a `render` operator that tells the UI how to visualize results.

### 6.1 Time charts

```kusto
Perf
| where TimeGenerated > ago(24h)
| where ObjectName == "Processor" and CounterName == "% Processor Time"
| summarize AvgCPU = avg(CounterValue) by bin(TimeGenerated, 15m), Computer
| render timechart
```

What happens:

- `bin(TimeGenerated, 15m)` groups data into 15‑minute buckets.
- `AvgCPU` is calculated for each VM and time bucket.
- `render timechart` shows a line chart (time on X axis, CPU on Y axis, one line per VM).

### 6.2 Other visualizations

Similar `render` types:
- `barchart`
- `piechart`
- `table` (default; you usually don’t need render for plain tables)

In the portal, you can also use the built‑in **Charts** tab above the results without writing `render`. But understanding `render timechart` helps interpret exam questions.

---

## 7. Building log alerts from queries (high level)

You can turn a log query into an **alert rule** (called a *scheduled query alert*).

High‑level flow:

1. Write and test your KQL query in **Logs**.
2. Click **New alert rule**.
3. Configure:
   - Target **workspace** or resource.
   - **Condition** – how often to run the query and what threshold triggers an alert.
   - **Action group** – who/what gets notified.
   - **Severity**, **name**, **description**.

Example:  
“Fire an alert if there are more than 10 failed sign‑ins in 5 minutes for the same user.”

Key differences vs metric alert:

- Log alerts are based on **KQL** and run at a defined **frequency** (e.g., every 5 minutes).
- Metric alerts are based on **metrics** and have near real‑time behavior.

---

## 8. Workspaces, scopes, and queries

### 8.1 Choosing the right workspace

A query runs against **one workspace at a time** by default.

- If you have multiple workspaces (Prod, Test, Dev), make sure you select the correct one.
- AZ‑104 might include questions where log data is “missing” because it was sent to another workspace.

### 8.2 Resource‑centric vs workspace‑centric

- **Workspace‑centric**:
  - You open Logs from the workspace.
  - You can query all tables in that workspace.

- **Resource‑centric**:
  - You open Logs from a resource (VM, App Gateway, etc.).
  - The query scope is automatically filtered to that resource.
  - This is easier when you only care about one resource.

---

## 9. Exam‑style scenarios

### Scenario 1 – Explain what the query does

You might see a query like:

```kusto
AzureActivity
| where ActivityStatus == "Failed"
| where TimeGenerated > ago(1d)
| summarize FailedOps = count() by ResourceGroup, OperationName
| order by FailedOps desc
```

You should be able to say:

> “This query shows, for the last day, how many failed operations occurred per resource group and operation, sorted by the highest number of failures.”

### Scenario 2 – Which query finds VMs with missing heartbeats?

Given multiple options, pick the one that:

- Uses the `Heartbeat` table.
- Groups by `Computer`.
- Checks if `max(TimeGenerated)` is older than a threshold.

### Scenario 3 – Which query counts 500 errors from an App Service?

Look for:

- A table containing HTTP logs (e.g., `AppServiceHttpLogs` or similar).
- `where StatusCode == 500`.
- `summarize count()` over a time window.

### Scenario 4 – Query to feed a log alert

You may see a requirement like:

> “Trigger an alert if more than 5 VMs have Avg CPU > 90% in the last 15 minutes.”

The pattern in KQL would:

- Use `Perf` or `InsightsMetrics` for CPU values.
- Aggregate by `Computer`.
- Count how many VMs exceed 90%.
- Compare that count against threshold.

---

## 10. Summary

To query and analyze logs in Azure Monitor, remember:

- Log data lives in **Log Analytics workspaces** as **tables**.
- You use **KQL** with a **table → pipe → operators** pattern.
- Key operators: `where`, `project`, `summarize`, `order by`, `take`, `extend`.
- Time filtering uses `TimeGenerated` and functions like `ago(1h)`.
- Visualization uses `render timechart` (or portal charts).
- Many exam questions are about **understanding** a KQL query, not writing one from scratch.

If you can read simple KQL and say:
- what table it uses,
- what it filters,
- how it groups (`summarize`), and
- what result it produces,

then you are ready for AZ‑104 questions on “Query and analyze logs in Azure Monitor”.

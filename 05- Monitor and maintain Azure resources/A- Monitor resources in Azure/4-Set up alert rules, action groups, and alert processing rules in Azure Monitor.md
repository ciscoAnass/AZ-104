# Set up alert rules, action groups, and alert processing rules in Azure Monitor

## 1. Why alerts are important

Monitoring is useless if nobody knows when something is wrong.

**Azure Monitor alerts** help you:
- Detect problems early (high CPU, failed requests, down VPN).
- Notify people or systems (email, SMS, ITSM, webhooks, runbooks).
- Automate responses (restart services, scale resources, open tickets).

In AZ‑104, you must understand:

1. **Alert rules** – what to watch and when to fire.
2. **Action groups** – who/what to notify.
3. **Alert processing rules** – how to modify or route alerts once they are fired.

---

## 2. Components of an alert rule

Every alert rule has these main parts:

1. **Scope**
   - The resource(s) being monitored.
   - Example: one VM, a resource group, a workspace, or an Application Insights resource.

2. **Condition**
   - What to check:
     - Metric value
     - Log query result
     - Activity log event
     - Service health or resource health

3. **Evaluation settings**
   - How often to check (e.g., every 1/5/15 minutes).
   - For what look‑back period (e.g., last 5 minutes).

4. **Actions**
   - Action groups to execute when the alert fires.

5. **Details**
   - Alert rule name and description.
   - Severity (0 = Critical … 4 = Informational).
   - Enabled/disabled status.

**Exam tip:**  
If you see a scenario “you must send an email when X happens” → think **alert rule + action group**.

---

## 3. Types of alert rules

### 3.1 Metric alerts (most common)

- Based on **metrics** (numeric time‑series).
- Examples:
  - `Percentage CPU > 80% for 5 minutes`
  - `Available memory < 20%`
  - `Storage account availability < 99%`

Key aspects:

- Near real‑time (often within a couple of minutes).
- Can be **single‑resource** or **multi‑resource** alerts (depending on metric).
- Support **static** or **dynamic** thresholds.

**Static threshold:**  
You define exact limit (e.g., CPU > 80%).

**Dynamic threshold:**  
Azure analyzes historical data to learn “normal” behavior and triggers when the value deviates (useful when usage varies a lot).

### 3.2 Activity log alerts

- Based on **Activity log** events (control‑plane operations).
- Examples:
  - When someone deletes a VM.
  - When a specific operation fails.
  - When a role assignment is created.

These alerts are configured on **Monitor → Alerts → + Create → Alert rule**, with **Activity log signal**.

### 3.3 Log alerts (scheduled query alerts)

- Based on a **KQL query** that runs on a schedule.
- Example:
  - “If there are more than 10 failed sign‑ins for the same user in 5 minutes.”
  - “If more than 100 HTTP 500 responses occur in 10 minutes.”

You configure:

- **Query** – KQL statement.
- **Frequency** – how often to run (e.g., every 5 minutes).
- **Period** – time window to look at (e.g., last 15 minutes).
- **Threshold** – result condition (`> 10`, `> 0`, etc.).

### 3.4 Other alert sources

You might also see references to:

- **Resource health alerts** – triggers when Azure marks a resource as unhealthy.
- **Service health alerts** – for Azure service issues in your region/subscription.
- **Smart detections** – intelligent detection in Application Insights.

For AZ‑104, know they exist, but the focus is mainly on **metric, activity log, and log alerts**.

---

## 4. Action groups – who gets notified and what happens

An **action group** is a reusable set of actions that run when an alert fires.

You define it once, then use it in many alert rules.

### 4.1 Possible actions

Common actions include:

- **Notifications**
  - Email
  - SMS
  - Push notification (via Azure mobile app)
  - Voice call

- **Automation / integration**
  - Azure Function
  - Logic App
  - Webhook
  - Azure Automation runbook
  - ITSM connector (create ticket in ITSM tool)

- **Others**
  - Secure webhook
  - Event Hub (for custom processing)

### 4.2 Creating an action group (portal)

1. Go to **Monitor → Alerts → Manage action groups**.
2. Click **+ Create**.
3. Select:
   - Subscription, resource group.
   - Action group name & short name (short name appears in notifications).
4. Under **Notifications** tab:
   - Add actions like Email/SMS/Push/Voice.
5. Under **Actions** tab:
   - Add automation actions (Logic App, Function, Runbook, Webhook, ITSM).
6. Review and create.

**Exam tip:**

- Reuse action groups (don’t create identical ones for each alert).
- One alert rule can have **up to 5** action groups.
- Many alert rules can use the **same** action group.

---

## 5. Alert processing rules – fine‑tune how alerts behave

Alert processing rules (previously called **action rules**) work **after** an alert is fired.

They let you:

- Suppress notifications during maintenance windows.
- Add or remove action groups based on conditions.
- Apply rules to many alerts at once (scoped by subscription, resource group, resource).

### 5.1 What can an alert processing rule do?

- **Mute** alerts for a period (e.g., during planned maintenance).
- **Route** alerts differently based on:
  - Resource or resource group.
  - Alert severity.
  - Alert rule name, monitor service, etc.
- **Add** extra action groups to alerts that don’t have them.

Important: The **alert still fires and is logged**, but processing rules can stop or change the **notifications**.

### 5.2 Example uses

- Suppress all alerts from `RG-Maintenance` every Sunday 01:00–03:00.
- Route critical alerts (severity 0–1) to on‑call mobile app, but send low severity (3–4) only by email.
- Add a special action group for backup alerts that don’t support action groups directly.

**Exam hint:**  
If the requirement says *“don’t send notifications during maintenance”*, but **do not disable** the alert rule, think **alert processing rule**.

---

## 6. Creating a metric alert – step by step

Example: Alert if VM CPU is above 80% for 5 minutes.

1. Go to **Monitor → Alerts → + Create → Alert rule**.
2. **Scope**: Choose the VM.
3. **Condition**:
   - Signal type: **Metric**.
   - Metric: `Percentage CPU`.
   - Aggregation: **Average**.
   - Threshold type: **Static**.
   - Condition: **Greater than** `80`.
   - Look‑back window: `5 minutes`.
4. **Actions**:
   - Select an **Action group** (e.g., email DevOps).
5. **Details**:
   - Name: `VM-CPU-High`.
   - Severity: `2` (Warning/High).
   - Enable the rule.
6. Review and create.

---

## 7. Creating a log alert (scheduled query alert) – step by step

Example: Alert when there are more than 10 failed sign‑ins in 5 minutes.

1. Write and test the KQL in **Logs** (workspace or resource):

```kusto
SigninLogs
| where ResultType != 0        // non‑success
| where TimeGenerated > ago(5m)
| summarize FailedCount = count()
```

2. In the Logs window, click **New alert rule**.
3. Configure:

   - **Scope**: The Log Analytics workspace.
   - **Condition**:
     - Configure **evaluation**:
       - Frequency: Every 5 minutes.
       - Period: Last 5 minutes.
     - Set **threshold**:
       - Alert when `FailedCount > 10`.
   - **Action group**: On‑call security team.
   - **Severity**: 1 (Critical).
   - **Name**: `Failed-Signins-High`.

4. Create the rule.

**Key differences vs metric alert:**

- Uses **KQL** instead of direct metric.
- Runs on a **schedule**.
- Works over any log table (very flexible, but can cost more).

---

## 8. Configuring alert processing rules – examples

### 8.1 Maintenance window (mute alerts)

Requirement:
> No email/SMS notifications from VM alerts during maintenance every Saturday 22:00–02:00.

Solution:

1. Go to **Monitor → Alerts → Alert processing rules**.
2. Click **+ Create**.
3. **Scope**: Resource group or specific VMs.
4. **Conditions**: (optional) Filter by severity, alert context, etc.
5. **Actions**: Choose **“Suppress notifications”**.
6. **Schedule**: Set recurring weekly schedule:
   - Start: Saturday 22:00
   - End: Sunday 02:00
7. Save.

Result: alerts still fire and are recorded, but notifications are not sent during the window.

### 8.2 Route critical alerts differently

Requirement:
> Critical alerts (severity 0–1) from production subscription should notify 24/7 on‑call; lower severity only via email.

Solution:

1. Create two action groups:
   - `AG-Prod-OnCall` – SMS/Push/Voice.
   - `AG-Prod-Email` – email only.

2. In the alert rules:
   - Attach `AG-Prod-Email` to all alerts by default.

3. Create an **alert processing rule**:
   - Scope: Production subscription.
   - Condition: Severity in {0, 1}.
   - Action: **Add action group** `AG-Prod-OnCall`.

Now, critical alerts trigger both email and on‑call actions, but low severity keeps only email.

---

## 9. Best practices for alerts

1. **Define alert strategy**
   - Don’t alert on everything.
   - Focus on issues that require human action.

2. **Use severity consistently**
   - Example:
     - 0 – Critical, service down.
     - 1 – High impact, user visible.
     - 2 – Degraded performance.
     - 3 – Warning, non‑urgent.
     - 4 – Informational, for dashboards only.

3. **Avoid alert storms**
   - Use **dynamic thresholds** where appropriate.
   - Tune conditions and time windows (e.g., CPU > 80% for 10 minutes, not for 1 min).
   - Use **alert processing rules** to suppress duplicates or maintenance noise.

4. **Test alerts**
   - Temporarily lower thresholds to confirm they fire and send expected notifications.
   - Document how to respond to each alert type.

5. **Use action groups for reusability**
   - One action group for each “audience” (DB team, network team, security team, etc.).
   - Reuse them across relevant alerts instead of repeating configuration.

6. **Separate environments**
   - Different alerts or action groups for Dev/Test vs Prod.
   - Prevent non‑production alerts from waking on‑call engineers.

---

## 10. Exam‑style scenarios

### Scenario 1 – Don’t disable the alert, but stop alerts during maintenance

Requirement:
> “During a weekly patch window, alerts should not send notifications, but we must still record them.”

Answer:
- Use an **alert processing rule** with a **schedule** that **suppresses notifications**.

### Scenario 2 – Use one configuration for many alerts

Requirement:
> “Send the same email and SMS notification for many different alert rules.”

Answer:
- Create a single **action group** with email + SMS.
- Attach the same action group to all relevant alert rules.

### Scenario 3 – Detect repeated failed sign‑ins using logs

Requirement:
> “Trigger an alert if any user has more than 5 failed sign‑ins in 10 minutes.”

Answer:
- Use a **log alert** (scheduled query alert) with KQL over `SigninLogs`.
- Group by user, count failures, and alert when threshold is exceeded.

### Scenario 4 – Choose metric vs log alert

- If monitoring **CPU, memory, disk, latency, transactions** → **metric alert**.
- If monitoring **complex conditions** like “multiple failures by same user” or “pattern in logs” → **log alert**.

---

## 11. Summary

For AZ‑104 you should be able to:

- Explain the structure of an **alert rule** (scope, condition, evaluation, actions, severity).
- Choose the correct **alert type** (metric, activity log, log alert, etc.).
- Configure and reuse **action groups** for notifications and automations.
- Use **alert processing rules** to suppress or redirect notifications based on time and conditions.

If you can read a requirement and answer:
- “Which alert type do I need?”
- “Which metric/log will I use?”
- “Which action group(s) are needed?”
- “Do I need an alert processing rule for routing or maintenance windows?”

then you are ready for the “Set up alert rules, action groups, and alert processing rules in Azure Monitor” objective in AZ‑104.

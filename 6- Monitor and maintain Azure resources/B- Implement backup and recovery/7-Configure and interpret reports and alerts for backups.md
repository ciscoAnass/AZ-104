# Configure and interpret reports and alerts for backups

Backups are only useful if you **know they’re working**.  
In Azure, monitoring and reporting for backup is mainly done through:

- **Azure Monitor metrics and alerts**
- **Backup jobs view** in vaults / Business Continuity Center
- **Backup Reports** (Azure Monitor Logs + Workbooks)
- **Email and other notifications** via **action groups**

In AZ‑104, you should understand how to:

- Configure alerts for backup failures.
- Use Backup center / Business Continuity Center to see backup status.
- Use reports to understand trends (storage use, job status, etc.).


## 1. Where monitoring lives: BCC / Backup center / Vaults

Today, there are two main “central” blades:

- **Business Continuity Center (BCC)** – newer unified experience for both Azure Backup and Site Recovery.
- **Backup center** – older but still widely used; often referenced in existing docs.

Both provide:

- At‑scale views of **backup items**, **jobs**, **alerts**, and **reports** across multiple vaults.
- Links into the underlying **Recovery Services vaults** and **Backup vaults**.

Individual vaults (Recovery Services vault or Backup vault) also expose:

- **Backup items**
- **Backup jobs**
- **Alerts** (for some experiences)
- **Diagnostic settings** to send logs to Azure Monitor.


## 2. Azure Backup jobs view

This is the first place to check when something fails.

### 2.1 From a vault

1. Open the **Recovery Services vault** or **Backup vault**.
2. Under **Monitoring**, select **Backup jobs**.
3. Filter by:
   - **Operation** – Backup, Restore, Configure backup, Delete, etc.
   - **Status** – In progress, Completed, Failed.
   - **Time range**.
4. Click a job to see:
   - **Error details**
   - Start/end time
   - Links to troubleshooting docs in many cases.

### 2.2 From Business Continuity Center / Backup center

1. Open **Business Continuity Center** (or **Backup center**).
2. Look for the **Jobs** or **Backup Jobs** view.
3. Filter by:
   - Subscription
   - Vault
   - Workload type
   - Time period

Use this for **at‑scale monitoring** across multiple vaults and workloads.

**Exam hint**

> If the question asks *“where would you go to see why a backup failed?”* the answer is usually  
> **Backup jobs** in the vault or **Business Continuity Center / Backup center** jobs view.


## 3. Alerts for backup and restore failures

Azure Backup integrates with **Azure Monitor alerts**.  
There are two main generations:

- **Classic Backup alerts** (older, vault‑specific)
- **Azure Monitor‑based alerts** (modern, recommended)

Today, the exam is likely to focus on Azure Monitor‑based alerts.

### 3.1 Built‑in alerts

For backup workloads, Azure provides **built‑in alerts** for common scenarios, such as:

- Backup job failed.
- Restore job failed.
- A scheduled backup was missed.

These alerts appear in:

- **Business Continuity Center ➜ Monitoring + Reporting ➜ Alerts**, or
- **Backup center ➜ Monitoring + Reporting ➜ Alerts**.

You can configure:

- Whether to **use only Azure Monitor alerts**.
- Whether to still receive older **classic alerts** (usually you disable them to avoid duplicates).

### 3.2 Configuring alert notifications with Azure Monitor

Azure Monitor alerts use:

- **Alert rules** (what to watch).
- **Action groups** (who to notify / what to do).

For backup, some alert rules are pre‑created for you, especially for job failures.

To manage notifications:

1. Open **Business Continuity Center** (or **Backup center**).
2. Go to **Monitoring + Reporting ➜ Alerts**.
3. Choose **Manage alerts / Alert processing rules**.
4. Link alerts to **Action groups** that can:
   - Send **email / SMS / push** notifications.
   - Call a **webhook**.
   - Trigger a **Logic App** or **Function**.
   - Open an **ITSM ticket**, etc.

Example use case:

- A backup failure alert triggers:
  - Email to `it-backup-team@contoso.com`.
  - A ticket in the ITSM system.

### 3.3 Suppression rules

Sometimes you want to **suppress** alert notifications, for example during maintenance.

- You can create an **alert processing rule** that:
  - Suppresses notifications for a specific time window (like 02:00–04:00 on Sunday).
  - Applies to a particular scope (subscription, resource group, or vault).

This doesn’t stop alerts from being generated; it just stops them from sending notifications.

**Exam idea**

> To avoid noisy alerts during planned maintenance, create an **alert processing rule** to suppress notifications for that time period.


## 4. Metrics for Azure Backup

Azure Backup exposes **metrics** through Azure Monitor, such as:

- Number of **successful** backups.
- Number of **failed** backups.
- **Backup items** in a vault.
- **Storage consumed** by backups (varies by workload and configuration).

You can:

1. Open the **vault** (Recovery Services or Backup vault).
2. Go to **Metrics**.
3. Select a namespace like **Azure Backup**.
4. Choose metrics and plot them on charts.
5. Create **metric alerts** when thresholds are crossed (for example, if the number of failed jobs > 0).

While AZ‑104 usually doesn’t ask you to build custom metrics from scratch, it might show screenshots and ask you to interpret them:

- A graph of **Backup Jobs (Failed)** spiking on a certain day.
- A chart of **Protected Items** by workload type.


## 5. Backup Reports (historical reporting and analysis)

For long‑term insights across many vaults and subscriptions, Azure provides **Backup Reports**, built on:

- **Azure Monitor Logs** (Log Analytics workspace)
- **Azure Workbooks**

### 5.1 Enabling Backup Reports

High‑level steps:

1. Decide which **Log Analytics workspace** you will use for backup logs.
2. In **Business Continuity Center** or **Backup center**:
   - Go to **Reports** or **Backup Reports**.
   - Configure vaults to send data to the chosen workspace.
3. Ensure diagnostic settings and data collection are configured for:
   - Backup items
   - Backup jobs
   - Alerts (if desired)

Once data flows into the workspace, pre‑built **Backup Reports** workbooks become available.

### 5.2 Using Backup Reports

In **Business Continuity Center ➜ Reports ➜ Backup Reports**, you can:

- View **summary dashboards**:
  - Protected items by workload and region.
  - Number of successful / failed jobs.
  - Trends over time.
- Drill down into:
  - Specific vaults.
  - Specific workloads.
  - Specific backup items.

Typical tabs include:

- **Overview** – high‑level health of backups.
- **Jobs** – statistics of backup/restore jobs over time.
- **Storage** – how much backup storage is consumed (useful for cost).
- **Policies** – which policies are used where.

Exam‑level understanding:

- Backup Reports is about **trend analysis**, **auditing**, and **capacity planning**.
- It is **not** primarily for real‑time troubleshooting (for that, use Backup jobs and Alerts).


## 6. Simple interpretation examples (exam style)

### Example 1 – Identify failed backups

Scenario:

- You’re told that some VM backups failed overnight.
- You must quickly see which VMs were affected.

Approach:

1. Open **Business Continuity Center ➜ Jobs** (or **Backup center ➜ Backup Jobs**).
2. Filter:
   - Time range: last 24 hours.
   - Operation: Backup.
   - Status: Failed.
3. Review affected items.

### Example 2 – Email when a backup job fails

Scenario:

- Requirement: “If any backup job fails, the backup team must receive an email notification.”

Approach:

1. Ensure **Azure Monitor‑based alerts** are enabled for backup jobs in your vaults.
2. Create or confirm **built‑in alert rules** for job failures.
3. Configure an **Action group** with:
   - Email receiver: `backup-team@contoso.com`
4. Associate that action group with the backup failure alerts (directly or via alert processing rule).

### Example 3 – See storage trend for backup data

Scenario:

- Requirement: “We suspect backup storage costs are increasing. Show a report of backup storage over the last 6 months.”

Approach:

1. Ensure vault diagnostic data is being sent to a **Log Analytics workspace**.
2. Open **Business Continuity Center ➜ Reports ➜ Backup Reports**.
3. Use the **Storage** tab to view:
   - Storage consumed per vault / workload over time.
4. Optionally export or schedule email reports.

### Example 4 – Too many alerts during maintenance

Scenario:

- Nightly maintenance window causes multiple VMs to be shut down and backups fail. This is expected, but the team receives too many alerts.

Approach:

1. Go to **Business Continuity Center ➜ Monitoring + Reporting ➜ Alerts**.
2. Create an **alert processing rule**:
   - Scope: the relevant vault or resource group.
   - Schedule: maintenance window.
   - Action: **suppress notifications**.
3. Keep the alerts in the system (for record), but don’t send emails during that window.


## 7. Classic alerts vs Azure Monitor alerts (high‑level)

**Classic alerts** (older):

- Configured directly on the **Recovery Services vault**.
- Limited to email notifications.
- Simple but less flexible.

**Azure Monitor alerts** (modern):

- Reusable across many Azure services.
- Use **action groups** and **alert processing rules**.
- Support multiple channels:
  - Email, SMS, mobile push.
  - Webhooks, Logic Apps, ITSM, etc.

As of now, the recommended practice is:

- **Use only Azure Monitor alerts** for Azure Backup.
- **Disable classic alerts** to avoid duplicates.

In the exam, if you must choose a direction for new deployments, pick Azure Monitor‑based alerts.


## 8. Quick checklist for AZ‑104

To be comfortable with “Configure and interpret reports and alerts for backups” you should:

- Know where to see **backup jobs** (vault, Business Continuity Center / Backup center).
- Know that **Azure Monitor** handles modern **alerts**:
  - Built‑in alerts for backup/restore failures.
  - Configurable **action groups** for notifications.
- Understand that **Backup Reports**:
  - Are based on **Log Analytics + Workbooks**.
  - Provide **historical** insights and trend analysis.
- Be able to read a screenshot that shows:
  - A spike in failed jobs.
  - A chart of storage consumption.
  - A list of alerts with severity and status.

---

### One‑sentence summary

> Azure Backup sends its health signals into **Azure Monitor** and **Backup Reports**, and you use **Backup jobs**, **Alerts**, **Metrics**, and **Reports** to keep your backups healthy and your DR story auditable.

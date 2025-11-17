# Create and configure a backup policy

## 1. What is a backup policy?

A **backup policy** defines:

- **When** backups run (schedule).
- **How long** backup copies are kept (retention).

Azure Backup uses policies to ensure consistent protection:

- You create a policy **once**.
- You **assign** it to one or more data sources (VMs, disks, file shares, etc.).
- Azure then automatically runs backups and prunes old recovery points according to that policy.

> Exam idea:  
> A backup policy = **schedule + retention**, applied to **many** items.


## 2. Policy concepts (core vocabulary)

Most policies, whether in a **Recovery Services vault** or a **Backup vault**, have similar concepts:

- **Schedule**
  - When to run backups (daily, weekly, hourly for some workloads).
  - Start time and time zone.
- **Retention**
  - How long to keep each recovery point.
  - Can include:
    - Daily
    - Weekly
    - Monthly
    - Yearly
  - Different retention per frequency.
- **Snapshot vs vaulted copies**
  - Some workloads use **local snapshots** and **vaulted backups**.
  - Policy can control retention in each tier.
- **Policy type / workload type**
  - Policy must match the **data source type**:
    - Azure VM (classic/enhanced)
    - Azure Files
    - Azure Disk Backup
    - Azure Blobs, etc.

You can usually **reuse** one policy for many resources with similar RPO/RTO requirements.


## 3. Creating a backup policy in a Recovery Services vault (Azure VMs example)

This is the classic scenario tested in AZ‑104.

### 3.1 Steps in the portal

1. Ensure you have a **Recovery Services vault** created in the same region as your VMs.
2. Open the vault.
3. In the left menu, select **Settings ➜ Backup policies**.
4. You’ll see built‑in policies like **DefaultPolicy**.
5. To create a new policy, select **+ Add** or **+ Backup policy**.
6. Choose the **Workload type**:
   - e.g. **Azure Virtual Machine**.
7. Configure the **Backup policy** details:
   - **Policy name** – e.g. `vm-daily-30d-12m-5y`.
   - **Backup schedule**:
     - **Frequency** – usually daily (classic policy) or hourly/daily (enhanced policy).
     - **Time** – for example, 22:00 (10 PM).
   - **Retention**:
     - **Daily** – keep backups for X days.
     - **Weekly** – choose one or more days and keep for X weeks.
     - **Monthly** – choose which day/week of month and keep for X months.
     - **Yearly** – choose month/day and keep for X years.
8. Save the policy.

Later, when you **enable backup** for a VM, you select this policy.

### 3.2 Example policy (classic Azure VM)

- **Backup**: Daily at 22:00.
- **Retention**:
  - Daily: keep for 30 days.
  - Weekly: keep the Sunday backup for 12 weeks.
  - Monthly: keep the last Sunday backup for 12 months.
  - Yearly: keep the last Sunday of March for 5 years.

This gives:

- Good short‑term granularity (30 days daily).
- Longer‑term compliance (yearly points).

### 3.3 Enhanced policy options (newer feature)

For some regions and workloads, you’ll see **Enhanced policy** options, such as:

- **Hourly backups** with RPO as low as 4 hours.
- Separate retention for:
  - **Instant restore snapshots** (kept in storage account).
  - **Vaulted backups** (kept in the vault).

You don’t need to memorize every numeric limit, but remember:

- Enhanced policies → more flexible schedules and retention.
- Good for workloads that need lower RPO.


## 4. Creating backup policies from Business Continuity Center

With the new **Business Continuity Center (BCC)** experience, you can centrally create backup policies.

1. Open **Business Continuity Center**.
2. In the left menu, choose **Manage ➜ Protection policies**.
3. Select **+ Create policy ➜ Create backup policy**.
4. On **Start: Create Policy**:
   - Choose **Datasource type** (e.g. Azure Disks, Azure VMs) and the **Vault type** (Recovery Services or Backup vault).
5. Configure:
   - **Schedule**: daily/weekly/hourly as allowed.
   - **Retention**: configure daily/weekly/monthly/yearly retention.
6. Save the policy.

These policies then appear in the corresponding vaults and can be applied when you enable backup on data sources.


## 5. Backup policies in a Backup vault (Data Protection workloads)

For Data Protection workloads (disks, blobs, etc.), policies are created **inside a Backup vault**.

Example: **Azure Disk Backup**

1. Open the **Backup vault**.
2. Go to **Backup policies**.
3. Select **Add** or **+ Backup policy**.
4. On the **Basics** tab:
   - Choose **Datasource type** = *Azure Disk*.
   - Provide a **policy name**.
5. Configure:
   - **Backup schedule**:
     - For example, every 12 hours, or once per day.
   - **Retention**:
     - Keep snapshots for a defined number of days/months/years.
   - Any **tiering** options (operational snapshots vs vaulted copies) if supported.
6. Save.

When you configure backup for disks or other supported workloads, you will select this policy.

Key ideas:

- Policy must match the **data source type**.
- A Backup vault can have **multiple policies** for the same data source type (for different RPO/RTO requirements).


## 6. Backup policy design and best practices

### 6.1 Think in terms of RPO and RTO

- **RPO (Recovery Point Objective)** – how much data you can afford to lose.
  - Shorter RPO (e.g. hourly backups) = more frequent backups, more storage, higher cost.
- **RTO (Recovery Time Objective)** – how long you can afford to be down.
  - More recovery points and well‑planned retention improve options, but still depend on how quickly you can restore.

For the exam:

- If a scenario requires **minimal data loss**, choose **more frequent backups**.
- If it requires **long‑term retention**, configure **monthly/yearly retention**.

### 6.2 Separate policies by workload criticality

- **Tier 1 apps** – maybe need daily backups + long retention.
- **Dev/Test** – might only need weekly or shorter retention.
- Avoid “one huge policy for everything” – it’s hard to manage and may be too expensive.

### 6.3 Avoid excessive retention

- Very long retention for every backup point can be costly.
- Better approach: shorter retention for daily backups, longer retention for weekly/monthly/yearly points.

### 6.4 Understand on‑demand backups vs policy

- **Scheduled backups** are driven by the **policy**.
- **On‑demand backups** are ad‑hoc:
  - You choose a custom retention period at backup time.
  - They’re useful before risky changes (patches, upgrades).
  - They don’t change the base policy; they just add an extra recovery point.


## 7. Configure a new policy for a VM and assign it (step‑by‑step example)

Example: create a policy and apply it to two VMs in the same region.

### Step 1 – Create the policy

1. Open the **Recovery Services vault**.
2. Select **Backup policies ➜ + Add**.
3. Select **Workload type = Azure Virtual Machine**.
4. Name it `vm-prod-daily-1y`.
5. Set **Schedule**:
   - Backup frequency: **Daily**.
   - Time: **22:00** local time.
6. Set **Retention**:
   - Daily: keep 30 days.
   - Weekly: keep Sunday backups for 8 weeks.
   - Monthly: keep last Sunday for 12 months.
   - Yearly: keep last Sunday in January for 3 years.
7. Save the policy.

### Step 2 – Apply the policy to VMs

1. In the same vault, go to **Backup items ➜ Azure Virtual Machine**.
2. Select **+ Add** or **+ Backup** (depending on UI).
3. Choose the **subscription**, **resource group**, and **VMs** in the same region.
4. When prompted for a **backup policy**, select `vm-prod-daily-1y`.
5. Enable backup and run the **initial backup**.

From now on:

- Backups run daily at 22:00.
- Retention follows the policy definition.


## 8. CLI/PowerShell examples (high‑level recognition)

You’re unlikely to be asked for exact syntax, but you might see code snippets.

### 8.1 Azure CLI – show and update policy (Recovery Services vault)

```bash
# List policies
az backup policy list       --vault-name rsv-prod-weu-01       --resource-group rg-prod-bcdr-weu

# Show a policy
az backup policy show       --vault-name rsv-prod-weu-01       --resource-group rg-prod-bcdr-weu       --name vm-prod-daily-1y
```

Some advanced scenarios use JSON templates to create policies, but AZ‑104 doesn’t expect you to build those from scratch.

### 8.2 PowerShell – create policy object (enhanced example outline)

```powershell
# Get an enhanced schedule policy object for Azure VMs
$schedulePolicy = Get-AzRecoveryServicesBackupSchedulePolicyObject `
  -PolicySubType Enhanced `
  -WorkloadType AzureVM

# Get a retention policy object
$retentionPolicy = Get-AzRecoveryServicesBackupRetentionPolicyObject `
  -PolicySubType Enhanced `
  -WorkloadType AzureVM

# Combine into a backup policy (simplified)
$policy = New-AzRecoveryServicesBackupProtectionPolicy `
  -Name "vm-prod-enhanced" `
  -WorkloadType AzureVM `
  -SchedulePolicy $schedulePolicy `
  -RetentionPolicy $retentionPolicy
```

You don’t need to memorize the parameters, but recognize that:

- These cmdlets operate on **backup policies**.
- They separate **schedule** and **retention** objects.


## 9. Exam‑style gotchas

- **Policy must match the vault and region**  
  You can’t apply a policy from one vault to items in another vault. Policies are scoped to their vault.

- **Policy changes apply going forward**  
  If you change a policy’s retention, it affects new backup points. Old points are pruned according to the new rules.

- **Only one vault per VM**  
  A VM can only be protected by **one** Recovery Services vault at a time.  
  Changing vault = stop protection and re‑enable backup in a new vault (and likely re‑attach a policy there).

- **Protection at scale**  
  Combine **Azure Policy** with **backup policies** to automatically enable backup for certain resource groups or tags.

---

### Quick review

- Backup policy = **when** to back up + **how long** to keep each backup.
- Policies are defined **per vault** and **per workload type**.
- You create the policy **once**, then **apply it to many resources**.
- Plan policies around **RPO/RTO** and **cost**.
- Use **Business Continuity Center ➜ Protection policies** or **vault ➜ Backup policies** to manage them.

If you can explain this in your own words, you’re ready for AZ‑104 questions about backup policies.

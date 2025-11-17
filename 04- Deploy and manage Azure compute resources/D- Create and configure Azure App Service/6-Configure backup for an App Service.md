# Configure backup for an App Service

## A. Why back up App Service?

Even though App Service is a managed platform, you are still responsible for:

- Your **application code and content**.
- Your **configuration settings**.
- Your **databases**.

Azure App Service provides a built‑in **Backup and Restore** feature so you can:

- Take on‑demand or scheduled backups.
- Restore to the same app, a different app, or a deployment slot.
- Include connected databases in the backup. citeturn1search3turn1search25

Backups are important in AZ‑104 scenarios around **business continuity and disaster recovery (BCDR)**.

---

## B. Requirements and limitations

Key requirements for the built‑in backup feature: citeturn1search3turn1search25turn1search18

- The app must run in **Standard tier or higher** (Standard, Premium, Isolated).
- You need an **Azure Storage account** and **blob container** in the same subscription.
- Backup size and frequency have limits (check current docs for exact numbers).
- Backups typically include:
  - App content (files)
  - App configuration
  - Selected databases (SQL Database, Azure Database for MySQL/PostgreSQL, etc.)

Things not covered or limited:

- Some App Service **logs** or external resources may not be included.
- Snapshots vs “traditional” backups have slightly different behaviour (snapshot backups rely on underlying storage snapshots). citeturn1search18

AZ‑104 won’t ask for exact numbers, but you should remember **the tier requirement and the dependency on Storage Account**.

---

## C. Configure backup in the Azure portal

1. **Open the web app**
   - In the portal, navigate to your app.

2. **Go to Backups**
   - In the left menu under **Settings**, select **Backups**. citeturn1search3

3. **Configure backup** (first time)
   - Click **Configure custom backups** or **Backup configuration**.
   - Choose:
     - **Storage account** – existing or create new.
     - **Container** – where backup blobs will be stored.
   - (Optional) **Databases**:
     - Include one or more databases that your app uses.

4. **Set backup schedule (optional but recommended)**
   - Enable **Scheduled backup**.
   - Set **frequency** (e.g., daily) and **retention** (how many backups to keep).

5. **Save** the configuration.

6. **Run a manual backup**
   - On the Backups page, click **Back up now** to create an immediate backup.

The Backups page will list:

- Status (Succeeded/Failed).
- Timestamp.
- Size.

---

## D. Restore from a backup

You can restore:

- To the **same app** (overwriting content & settings).
- To a **different app**.
- To a **deployment slot** (best practice to avoid downtime). citeturn1search3turn3search1

**Portal steps (high level)**:

1. In the app’s **Backups** blade, select the backup you want.
2. Click **Restore**.
3. Choose **restore target**:
   - This app
   - Another app
   - A deployment slot
4. Confirm that you understand the restore impact (overwrites content/config, app may be stopped during restore).
5. Click **OK** to start restore.

Notes:

- During restore, the **target app or slot is stopped**, causing downtime if you restore directly to production. That’s why docs recommend restoring to a **slot** and then swapping. citeturn1search3
- Databases restore depends on the selected options; sometimes you restore database backups separately (e.g., SQL Point‑in‑Time Restore).

---

## E. Backup using PowerShell and CLI

You might see examples on the exam that use PowerShell/CLI commands.

### PowerShell (one‑time backup)

```powershell
$rg = "rg-az104-webapps"
$appName = "az104-demo-web"
$storageAccount = "az104backupsa"
$containerName = "webappbackups"

# Trigger a one-time backup
New-AzWebAppBackup `
  -ResourceGroupName $rg `
  -Name $appName `
  -StorageAccountUrl "https://$storageAccount.blob.core.windows.net/$containerName" `
  -FrequencyInterval 0 `
  -FrequencyUnit "Day"
```

PowerShell cmdlets like `Edit-AzWebAppBackupConfiguration` can configure scheduled backups and retention. citeturn1search16

### Azure CLI (concept)

At time of writing, Azure CLI doesn’t have a single dedicated `az webapp backup` command for all scenarios, but you should know that **ARM templates** / **Bicep** or PowerShell are commonly used to automate backup configuration.

---

## F. Using deployment slots for safer restores

A common pattern:

1. App has a **production slot** and a **staging slot**.
2. When you need to restore, you restore **to staging** first.
3. Verify the app works correctly.
4. **Swap** staging into production (deployment slots swap). citeturn3search1

Advantages:

- Minimizes production downtime.
- Allows testing restored version with real configuration.

---

## G. Alternative recovery strategies

In addition to built‑in Backups, Azure provides other BCDR options: citeturn1search18turn1search3

- **Source control** (Git)
  - Redeploy code from Git repo (if app code is stateless).
- **Infrastructure as Code** (ARM/Bicep/Terraform)
  - Recreate App Service and configuration from templates.
- **Database backups**
  - Use Azure SQL Database automatic backups or PITR.
- **App cloning**
  - Use cloning features or script deployment to another region.

In exam questions, look for when it’s appropriate to use **built‑in backup** vs **redeploy from source** or **database restore**.

---

## H. Best practices and exam tips

1. **Tier awareness**
   - Backup/restore requires **Standard tier or higher**. If you see an app on Basic that must support scheduled backups → **scale up** the plan. citeturn1search25turn1search1

2. **Include databases carefully**
   - Make sure database connections used during backup have proper permissions.
   - Consider also native DB backup/restore for more granular control.

3. **Use separate storage account for backups**
   - Keep backups in a resilient storage account (e.g., GRS).
   - Separate backup storage from production data.

4. **Test restores regularly**
   - A backup is only useful if restore works and you know the steps.

5. **Combine with deployment slots**
   - Restore to **staging slot** to avoid downtime; then swap when ready.

6. **Cost considerations**
   - You pay for:
     - **App Service plan tier** (Standard+)
     - **Storage account** capacity used by backup blobs
   - Use retention policies to avoid unbounded growth.

If you can explain when built‑in backups are available, how to configure them in the portal, and the basic restore flow, you’ll be well prepared for this AZ‑104 objective.

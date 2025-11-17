# Perform backup and restore operations by using Azure Backup

This section focuses on **practical operations**:

- Enable backup for common workloads (especially Azure VMs).
- Run **on‑demand backups**.
- Monitor **backup jobs**.
- Restore:
  - Entire VMs
  - Disks
  - Files and folders
  - Azure Files shares (high level)

The examples concentrate on **Recovery Services vaults** because that’s where most AZ‑104 questions are.

---

## 1. Enable backup for an Azure VM (Recovery Services vault)

### 1.1 From the VM blade (common exam scenario)

1. In the Azure portal, go to **Virtual machines**.
2. Select the VM you want to protect.
3. In the left menu under **Backup + disaster recovery**, select **Backup**.
4. In the **Backup** pane:
   - **Recovery Services vault**:
     - Select an existing vault **in the same region** as the VM, or
     - Create a new vault.
   - **Backup policy**:
     - Select an existing policy (e.g. `vm-prod-daily-1y`) or create a new one.
5. Click **Enable backup**.

Azure will:

- Register the VM with the vault.
- Schedule the **initial backup** at the next scheduled time.
- You can also start an **on‑demand backup** right away (see below).

### 1.2 From the Recovery Services vault (multiple VMs at once)

1. Open the **Recovery Services vault**.
2. Go to **Getting started ➜ Backup** or **Backup items ➜ Azure Virtual Machine ➜ + Add**.
3. Select:
   - **Where is your workload running?** → *Azure*.
   - **What do you want to back up?** → *Azure Virtual Machine*.
4. On the **Backup policy** page:
   - Select or create a policy.
5. On **Select virtual machines**:
   - Select one or more VMs in the same region as the vault.
6. Click **Enable backup**.

**Exam note**

> You cannot back up a VM to a vault in another region.  
> If the vault region and VM region are different, the portal will not let you proceed.


## 2. On‑demand backup (manual backup)

Sometimes you need a manual backup outside the schedule:

- Before installing a large update.
- Before a risky configuration change.

### Steps

1. Open the **Recovery Services vault**.
2. Go to **Backup items ➜ Azure Virtual Machine**.
3. Select the VM you want to back up.
4. Click **Backup now**.
5. Choose a **Retention** value for this on‑demand backup (for example, 7 days, 30 days, etc.).
6. Click **OK** to start the job.

Points to remember:

- On‑demand backups create an **extra recovery point** with its own retention.
- They **don’t change** the regular schedule defined in the policy.


## 3. Monitor backup jobs

Backup operations generate **jobs** – for both backup and restore.

### 3.1 From the vault

1. Open the **Recovery Services vault**.
2. Under **Monitoring**, select **Backup jobs**.
3. Filter by:
   - **Operation** (Backup, Restore, Configure backup, etc.)
   - **Status** (In progress, Completed, Failed).
   - **Time range**.

You can click a job to see details, error messages, and logs.

### 3.2 From Business Continuity Center / Backup center

- Open **Business Continuity Center** (or **Backup center**, depending on the portal version).
- Use the **Jobs** or **Backup Jobs** blade to see jobs across multiple vaults.
- This unified view is helpful at scale.

### 3.3 Common errors to recognize

- **Policy/region mismatch** – VM and vault are in different regions.
- **Permissions** – the identity used to configure backup lacks required rights.
- **Extension failures** – backup agent/extension on the VM failed to run (for example, due to OS or network issues).

In exam questions, they often tell you a backup job failed and ask where to see more details → answer: **Backup jobs**.


## 4. Restore an Azure VM

You can restore:

- A **whole VM** (new or replace existing).
- **Disks only**, to attach to another VM.
- **Files/folders** via a temporary mount (next section).

### 4.1 Restore a VM (new VM)

1. Open the **Recovery Services vault**.
2. Go to **Backup items ➜ Azure Virtual Machine**.
3. Select the VM you want to restore.
4. Click **Restore VM**.
5. Choose:
   - **Restore point** (date/time).
   - **Restore type**:
     - **Create new**: deploy a **new VM**.
     - **Replace existing**: overwrite the existing VM (when allowed).
6. If you choose **Create new**:
   - Provide:
     - **New VM name**
     - **Resource group**
     - **Virtual network / subnet**
     - **Availability options** (zone, set as allowed)
7. Confirm and start the restore.

Azure Backup will:

- Create new disks from the selected recovery point.
- Provision a new VM using those disks.

### 4.2 Restore disks only

Useful when:

- You want to attach restored disks to an existing VM.
- You only want data, not full VM configuration.

Steps (high level):

1. In the vault, open **Backup items ➜ Azure Virtual Machine ➜ <VM>**.
2. Select **Restore**.
3. Choose **Restore type = Disks**.
4. Select a **Restore point**.
5. Specify:
   - Target **resource group**.
   - **Storage account** or temporary placement for the restored disks (depending on UI).
6. Run the restore.

After the job completes:

- The restored managed disks appear as new disk resources.
- You can attach them to any VM in the same region.

### 4.3 “Replace existing” restore

- Overwrites the existing VM with data from the recovery point.
- Requires downtime.
- Not always available (for example, some OS / configuration conditions).

Exam pattern:

- **Migration / test**: choose **Create a new VM**.
- **Rollback after failed change**: choose **Replace existing** (if supported).


## 5. Restore files and folders from a VM backup

Sometimes you just need a few files, not a whole VM.

Azure Backup supports **file‑level restore** from VM backups using a **temporary mount**.

### Concept

- Azure Backup creates a **temporary disk** visible to a VM (or a client machine).
- You browse that disk and copy files back.
- When you’re done, you unmount/disconnect.

### Steps (portal, high level)

1. In the **Recovery Services vault**, go to **Backup items ➜ Azure Virtual Machine ➜ <VM>**.
2. Click **File Recovery** (or **Restore files**, depending on UI).
3. Select the **Restore point** you want to use.
4. Azure generates a **script** (PowerShell for Windows, shell script for Linux) or a **downloadable executable**.
5. Download the script and note any **password**/token provided.
6. Run the script **inside the VM** (or in a machine that can access the VM’s disks as documented).
   - The script attaches the recovery point as a **temporary network drive or mounted disk**.
7. Copy the required files/folders from that drive to the normal file system.
8. After finishing, return to the portal and select **Unmount / Stop File Recovery**.

Exam‑friendly summary:

> To restore individual files from an Azure VM backup, you use **File Recovery**, which mounts the backup as a temporary drive using a downloadable script.


## 6. Back up and restore Azure Files (high‑level)

Azure Files backup is also configured through a vault (often a Recovery Services vault, depending on your region and features).

### 6.1 Enable backup for Azure Files

1. In the portal, go to the **storage account** that contains your file share.
2. Under **Data protection / Backup**, choose:
   - **Backup goal**: *Azure Files (Storage account)*.
   - **Vault**: select an existing vault in the same region or create a new one.
   - **Policy**: choose or create a policy for Azure Files.
3. Select the **file shares** to protect.
4. Enable backup.

Azure Backup uses **file share snapshots** and possibly vaulted copies depending on configuration.

### 6.2 Restore Azure Files

1. Open the **Recovery Services vault** or **Backup vault** managing the file share backup.
2. Go to **Backup items ➜ Azure Files (Azure Storage)**.
3. Select the file share.
4. Choose **Restore**.
5. Options typically include:
   - Restore the **entire file share** to the **original** or an **alternate** location.
   - Restore **specific files/folders**.
6. Provide target details and start the restore job.

Again, focus on **concepts** for AZ‑104:

- Backups are **configured on the storage account** with a **vault + policy**.
- Restores are initiated from the **vault ➜ Backup items ➜ Azure Files**.


## 7. Canceling backup and deleting data

Sometimes you need to stop protecting an item:

1. In the **Recovery Services vault**, go to **Backup items**.
2. Choose the workload type (Azure VM, Azure Files, etc.).
3. Select the protected item (VM, file share).
4. Select **Stop backup**.
5. You’ll usually get two options:
   - **Stop protecting and retain backup data** – keeps recovery points for later restore.
   - **Stop protecting and delete backup data** – deletes recovery points (subject to soft delete).

If **soft delete** is enabled:

- Even after deleting backup data, it remains in a soft‑delete state for a set period.
- You can still recover it or permanently remove it via extra steps.

Important exam message:

> You can’t simply delete the vault while there are protected items or backups.  
> You must **stop backup**, handle soft delete if needed, and only then delete the vault.


## 8. Quick command awareness (CLI)

You don’t have to memorize full syntax, but recognize these patterns for Recovery Services vaults:

- Enable backup for a VM:

  ```bash
  az backup protection enable-for-vm         --resource-group rg-prod-weu         --vault-name rsv-prod-weu-01         --vm vm-prod-01         --policy-name vm-prod-daily-1y
  ```

- Trigger an on‑demand backup:

  ```bash
  az backup protection backup-now         --resource-group rg-prod-weu         --vault-name rsv-prod-weu-01         --item-name vm-prod-01         --backup-management-type AzureIaasVM         --retain-until 2025-12-31
  ```

- List jobs:

  ```bash
  az backup job list         --resource-group rg-prod-weu         --vault-name rsv-prod-weu-01
  ```

If you see `az backup` commands, think **Recovery Services vault** operations.


## 9. Exam‑style scenarios

1. **“Before installing a major line‑of‑business app update, you must be able to quickly revert the VM.”**  
   - Action: Run an **on‑demand backup** with enough retention.

2. **“You need to restore a single file that was deleted from a VM’s OS disk.”**  
   - Use **File Recovery** → download script → mount recovery point → copy file back.

3. **“You need to test a patch by restoring a VM to a test environment without impacting production.”**  
   - Use **Restore VM**, choose **Create new VM** into a different resource group/network.

4. **“You must minimize downtime and data loss during restore.”**  
   - Choose the most recent **app‑consistent** recovery point if available.

5. **“You can’t delete a Recovery Services vault because it still contains backup items.”**  
   - Solution: **Stop backup** for each item, handle soft delete, then delete vault.

---

### Final recap

For AZ‑104, be ready to explain:

- How to **enable backup** for an Azure VM/file share.
- How to **start a manual backup**.
- Where to **monitor backup jobs**.
- How to **restore**:
  - a full VM,
  - just disks,
  - individual files,
  - Azure Files.
- The impact of **soft delete** on backup deletion.

If you can walk through those flows confidently, you’re ready for most backup/restore questions on the exam.

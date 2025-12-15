# Move a Virtual Machine to Another Resource Group, Subscription, or Region

## A. Why Move a VM?

Common reasons:

- Reorganizing resources for better governance (new naming or RG structure).
- Moving workloads to a different **subscription** (for billing/ownership).
- Moving to a new **region** (closer to users, new region opened, DR strategy).

For the AZ‑104 exam, you must know:

- What is supported with **Move** operations.
- How to move within the same region (between RGs or subscriptions).
- How to move to **another region** (tools and patterns).
- Limitations and special cases (disk encryption, Marketplace images, backups).

---

## B. Moving a VM Between Resource Groups or Subscriptions (Same Region)

### 1. Basic rules

- You can move a VM and its dependent resources to:
  - Another **resource group** in the same subscription.
  - Another **subscription** in the same **tenant**.
- The VM stays in the **same region**.
- You must move **dependent resources together**, for example:
  - VM
  - OS/data disks
  - NIC(s)
  - Public IP
  - NSG
  - Availability set (if used)
- Source and target subscriptions must be in the **same Azure AD tenant**.

During the move:

- The **source and target resource groups are locked** for write/delete operations until the move completes.
- Existing workloads usually continue running; move itself doesn’t stop the VM (except in special cases).

Exam tip: If a question mentions that both resource groups are locked and you cannot modify resources while moving → that’s expected behavior during a resource move.

### 2. Move in the Azure Portal

**Scenario:** Move a VM from `rg-old` to `rg-new` in the same subscription.

Steps:

1. Go to the **Resource group** that currently contains the VM (`rg-old`).
2. Click **Move** on the toolbar.
3. Choose:
   - **Move to another resource group** or
   - **Move to another subscription**.
4. Select all related resources for the VM (VM, disks, NIC, public IP, NSG, availability set, etc.).
5. Choose the **target resource group** and subscription.
6. Check the **validation** result; the portal shows if any resource cannot be moved.
7. Confirm the move and wait for completion.

If the VM uses backup, ADE, or Marketplace plans, you may see validation errors and must follow special guidance (see below).

### 3. Move using Azure CLI

You can use `az resource move` to move resources.

```bash
# Get full IDs for VM and its resources (simplified example)

SOURCE_RG="rg-old"
TARGET_RG="rg-new"

# Example: move VM and its NIC
IDS=$(az resource list \
  --resource-group $SOURCE_RG \
  --query "[?name=='vm-app01' || name=='vm-app01-nic'].id" \
  -o tsv)

# Move the resources
az resource move \
  --destination-group $TARGET_RG \
  --ids $IDS
```

To move across subscriptions, add `--destination-subscription-id <target-sub-id>` and ensure the target subscription is in the same tenant.

### 4. Move using PowerShell (high level)

```powershell
$sourceRg = "rg-old"
$targetRg = "rg-new"

$resources = Get-AzResource -ResourceGroupName $sourceRg |
    Where-Object { $_.Name -in @("vm-app01", "vm-app01-nic") }

Move-AzResource -DestinationResourceGroupName $targetRg -ResourceId $resources.ResourceId
```

Again, include all dependent resources for the VM.

---

## C. Special Cases and Limitations

Some VM configurations require additional steps when moving:

1. **Disk encryption (Azure Disk Encryption, CMK)**  
   - Encrypted VMs may have restrictions when moving between subscriptions or RGs.
   - You might need to:
     - Ensure Key Vault and disk encryption sets exist in the target subscription.
     - Temporarily disable backup or ADE in complex scenarios.
   - Always check the latest “move limitations for virtual machines” documentation for detailed rules.

2. **Marketplace images with plans**  
   - If the VM was created from a Marketplace image with a plan, the target subscription must have accepted the same offer/plan.
   - Otherwise, move may fail.

3. **Backups (Recovery Services vault)**  
   - If the VM is protected by Azure Backup, you may need to stop protection, move, then re‑enable backup in the target subscription or vault.

4. **Classic resources**  
   - Classic deployment model (ASM) resources are mostly retired/not relevant for AZ‑104, but historically were harder or impossible to move.
   - For the exam, focus on **ARM‑based** VMs.

Exam tip: When you see a multiple‑choice question about moving an encrypted VM or one with backup enabled, look for answers that mention **special requirements** or **using documented migration procedures**, not just “click move and it will work”.

---

## D. Moving a VM to Another Region

Moving across **regions** is more complex. There is **no simple “move” button** that changes the region field of a VM. Instead, Azure offers migration solutions that **re-create** resources in the new region.

### Main options:

1. **Azure Resource Mover** (recommended where supported)
2. **Azure Site Recovery** in “move” mode
3. **Manual migration** (image/snapshot + re‑create VM)

### 1. Azure Resource Mover

Azure Resource Mover is a service that moves Azure resources between regions in an orchestrated way.

High‑level workflow when moving VMs:

1. In the portal, search for **Azure Resource Mover**.
2. Create a **Move collection** and select:
   - Source subscription and region.
   - Target subscription and region.
3. Select resources to move (VMs, NICs, VNet, public IP, NSG, etc.).
4. Prepare and initiate the move:
   - Resource Mover uses **Site Recovery** under the hood for VM replication.
   - Disks are replicated to the target region.
5. Test or commit the move:
   - VMs are created in the target region.
   - You can choose to perform a **test migration** first.
6. After validation, **commit** and clean up source resources if desired.

Benefits:

- Handles many dependencies automatically.
- Supports moving multiple resource types together.
- Can move across subscriptions & regions in one workflow (where supported).

Exam tip: If the requirement is “move existing VMs to a different region with minimal downtime and retain configuration” → think **Azure Resource Mover** as the main answer.

### 2. Azure Site Recovery (ASR) as migration tool

Azure Site Recovery is usually a **DR/replication** service, but it can also be used to **migrate** VMs to another region:

1. Create a **Recovery Services vault** in the target region.
2. Enable **replication** for the VM from source to target region.
3. Once replication is caught up, perform a **planned failover** to the target region.
4. Verify workload and then **commit**.
5. Decommission VMs in the source region if no longer needed.

Use cases:

- When Resource Mover isn’t supported or you are already using ASR.
- When you want DR and eventual permanent move to a new region.

### 3. Manual Migration (Snapshot / Image + Re‑create)

Manual method (more steps, more downtime):

1. **Stop and generalize** the VM (if needed).
2. Create a **managed image** or **snapshot** of the disk.
3. **Copy** snapshot or image to a storage account or compute gallery in the target region.
4. In the **target region**, create a **new VM** from the copied image/snapshot.
5. Re‑attach data disks (copied similarly).
6. Recreate networking (VNet, subnets, NSGs, LB) and other services (Key Vault, Backup, etc.).
7. Update DNS and application configuration to point to the new VM.

Exam tip: If the question describes a simple, one‑off migration without mention of Resource Mover/ASR, you might see answers referencing **image/snapshot + new VM in target region**.

---

## E. Choosing the Right Move Approach (Exam View)

| Goal | Recommended Tool |
|------|------------------|
| Reorganize resources into new RGs/subscriptions, same region | Built‑in **Move** operation in portal/CLI/PowerShell. |
| Migrate VMs and associated resources to another region with orchestration | **Azure Resource Mover**. |
| Use DR replication and then permanently move to new region | **Azure Site Recovery** migration scenario. |
| One‑off migration, simple environment | Manual: snapshot/image → copy → create VM in new region. |

Watch for keywords:

- “Move to another subscription in the same tenant” → resource move.
- “Move to another region” + “minimal downtime” + “orchestrate dependencies” → Azure Resource Mover.
- “Use existing replication service for DR that can also be used for migration” → ASR.

---

## F. Best Practices

1. **Plan dependencies**
   - List NICs, NSGs, disks, load balancers, public IPs, Key Vaults, etc.
   - Ensure they are included in the move or recreated in the new region/RG.

2. **Check limitations first**
   - Review documentation for move limitations related to VMs, encryption, backup, and Marketplace plans.

3. **Use test moves where possible**
   - Azure Resource Mover and ASR allow **test migrations** before cutting over.

4. **Minimize downtime**
   - Schedule the final cutover during a maintenance window.
   - Update DNS records with low TTL before migration so they can be switched quickly.

5. **Update governance and monitoring**
   - After the move, confirm that:
     - Azure Policy still applies appropriately.
     - Role assignments (RBAC) still meet requirements.
     - Backup and monitoring are configured in the target RG/subscription/region.

---

## G. Quick Exam Summary

- **Move across RG/subscription (same region)** → use **Move** (portal/CLI/PowerShell), include **VM + dependencies**, both RGs locked during move.
- **Encryption/backup/Marketplace‑based VMs** may require additional documented steps.
- **Region change** requires **re‑creating** resources in new region:
  - Azure Resource Mover (preferred),
  - Azure Site Recovery (migration scenario),
  - or manual snapshot/image + new VM.
- Moving resources does **not** change their resource IDs structure completely (subscription/RG parts change) and may affect scripts or automation that assume hard‑coded IDs.

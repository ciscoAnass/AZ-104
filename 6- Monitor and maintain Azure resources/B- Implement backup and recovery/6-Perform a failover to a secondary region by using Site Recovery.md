# Perform a failover to a secondary region by using Site Recovery

Once Azure Site Recovery (ASR) is configured and VMs are replicating, the next step is understanding **failover**:

- **Test failover** – DR drill without impacting production.
- **Planned failover** – controlled move with no (or minimal) data loss.
- **Unplanned failover** – real disaster, primary site is down.

In AZ‑104, you should know:

- The differences between these failover types.
- How to trigger a failover from the portal.
- What happens after failover (commit & reprotect).


## 1. Failover concepts

### 1.1 Types of failover

1. **Test failover**
   - Used for **DR drills**.
   - Creates VMs in the target region using replicated data.
   - **Does not affect** ongoing replication or production VMs.
   - Typically uses a **non‑production network** (test VNet).

2. **Planned failover**
   - Use when the **primary site is still available** and you want to move workloads in a controlled way (maintenance, migration).
   - Workflow:
     - Shut down source VMs.
     - Replicate remaining changes.
     - Fail over to the target region.
   - Goal: **zero or minimal data loss**.

3. **Unplanned failover**
   - Use during an **actual disaster** when the primary site is not accessible.
   - Uses the **latest available recovery point** in the target region.
   - Some recent data may be lost (depending on RPO).

### 1.2 Recovery points

When you trigger failover, you choose a **recovery point**:

- **Latest processed** – lowest RTO (quickest), uses the latest replicated data already processed on the target.
- **Latest app‑consistent** – uses the most recent app‑consistent snapshot.
- **Custom** – pick a specific timestamp.

Exam questions may ask which recovery point type to pick to:

- Minimize downtime → *Latest processed*.
- Ensure best application consistency → *Latest app‑consistent* or a specific point.


## 2. Test failover (disaster recovery drill)

**Goal**: verify your DR plan without impacting production.

### Recommended approach

- Use a **separate test VNet** in the target region.
- Avoid connecting test VMs to production networks.
- Clean up test resources after the drill.

### Steps for a single VM (high level)

1. Open the **Recovery Services vault** used for Site Recovery.
2. Under **Site Recovery**, select **Replicated items**.
3. Select the VM you want to test.
4. Click **Test failover**.
5. Choose:
   - **Recovery point** (for example, Latest processed or Latest app‑consistent).
   - **Target network**: select a **non‑production VNet** in the target region.
6. Start the test failover.

ASR will:

- Create a **test VM** in the target region based on the chosen recovery point.
- Leave the original VM and replication untouched.

### After the test

1. Validate that the **test VM boots** and applications run as expected.
2. Perform functional tests.
3. When finished, go back to the replicated item and select **Cleanup test failover**.
4. Optionally record test notes (for compliance/audit).

**Exam note**

> Test failover is the safest way to check your DR strategy. It does **not** break replication or bring down production.


## 3. Planned failover

Used when:

- You plan to move workloads (for example, migration to another region).
- The **source region is available**.

### Steps (Azure‑to‑Azure, high level)

1. Notify stakeholders of planned downtime.
2. In the **Recovery Services vault ➜ Site Recovery ➜ Replicated items**, select the VM or **recovery plan**.
3. Choose **Planned failover**.
4. Select direction (usually **Primary to Secondary**).
5. ASR will:
   - Shut down the source VM.
   - Synchronize final changes to the target.
   - Bring up the VM in the target region.

After failover:

- The VM runs in the **secondary region**.
- Clients should be redirected via:
  - DNS changes
  - Traffic Manager / Front Door
  - Load balancer configuration

**Key benefit**: minimal or zero data loss because the last changes are replicated while the source is still up.


## 4. Unplanned failover

Use when:

- The **primary region or site is down**.
- You can’t gracefully shut down source VMs.

### Steps

1. In the **Recovery Services vault**, go to **Site Recovery ➜ Replicated items** or **Recovery plans**.
2. Select the affected VM(s) or plan.
3. Click **Failover** (unplanned).
4. Choose:
   - Recovery point type:
     - Usually **Latest processed** or **Latest app‑consistent**.
5. Confirm failover.

ASR will:

- Bring up VMs in the **target region** using the selected recovery point.
- Source VMs are assumed to be unavailable.

After failover, you’ll operate from the **secondary region** until the primary is back and you perform **failback**.


## 5. Failover using recovery plans

For multi‑tier apps (web, app, DB), you can group VMs into a **Recovery plan**:

- Defines **order** of failover:
  - Tier 1 (DB) → Tier 2 (app servers) → Tier 3 (web servers).
- Can include **scripts or Azure Automation runbooks** (for example, update DNS, reconfigure load balancer).

For the exam, know that:

- Recovery plans simplify **failover for multiple VMs**.
- You run **Test failover**, **Planned failover**, or **Unplanned failover** **on the plan**, not each VM.

Typical steps:

1. In the vault, go to **Site Recovery ➜ Recovery plans**.
2. Select the plan.
3. Choose **Test failover** or **Failover**.
4. Follow the wizard to select recovery point, target network, etc.


## 6. After failover: commit and reprotect

A failover is not fully completed until you:

- **Commit** the failover.
- **Reprotect** (start replication in the opposite direction).

### 6.1 Commit

After failover:

- You confirm that VMs are working in the target region.
- Then you **commit** the failover to:
  - Remove obsolete recovery points.
  - Clean up temporary artifacts.

In the portal:

- On the **Replicated item** or **Recovery plan**, click **Commit**.

**Important:** Commit is **irreversible** for that failover operation (you can’t “undo” and go back to pre‑failover state).

### 6.2 Reprotect (failback preparation)

Once workloads are running in the secondary region, you usually want to **protect them again**, so that:

- Data is replicated from the **secondary** back to the **primary** region.
- Later, you can **fail back** to the original region when it is healthy.

Steps (high level):

1. On the replicated item, select **Re‑protect**.
2. Configure:
   - New **source** (current region).
   - New **target** (original region).
   - Replication policy and target VNet/RG on the original side.
3. Wait until replication is healthy again.
4. Later, run **planned failover** from secondary → primary to fail back.

Exam idea:

> “After failing over to the secondary region, you must start replicating changes back to the original region.”  
> → Use **Re‑protect** (then planned failover later to fail back).


## 7. Example: Full DR flow (simplified)

1. **Before disaster**
   - VM is in `West Europe`, replicating to `North Europe`.
   - Replication health is **Healthy**.

2. **Run a test failover** (periodic DR drill)
   - Use **Test failover** from the vault.
   - Target a **test VNet**.
   - Validate the app.
   - Clean up test failover.

3. **Actual outage hits West Europe**
   - Decide to trigger **unplanned failover**.
   - In the vault, select the **Recovery plan** or VM and click **Failover**.
   - Choose **Latest app‑consistent** recovery point.
   - VMs start in `North Europe`.

4. **Operate from secondary region**
   - Update DNS / traffic routing to point to `North Europe`.
   - Application is serving users from the DR site.

5. **Primary region is restored**
   - In the vault, choose **Commit** on each failover.
   - Then select **Re‑protect** to begin replication from `North Europe` back to `West Europe`.

6. **Fail back**
   - Once replication is healthy and you’re ready, run **planned failover** from `North Europe` back to `West Europe`.
   - Commit again.
   - Re‑protect so that replication is once again primary → secondary.


## 8. Exam‑style differences to remember

- **Test failover vs Failover**
  - Test failover:
    - No impact on production.
    - For **drills** and validation.
    - Uses a **test network**.
  - Failover (planned/unplanned):
    - Actually moves production workload to DR site.
    - Involves downtime and possibly data loss (unplanned).

- **Planned vs Unplanned failover**
  - Planned:
    - Source is still available.
    - Shuts down source VMs and synchronizes final changes.
    - Aim for **no data loss**.
  - Unplanned:
    - Source is down.
    - Uses latest available recovery point.
    - Some data since last replication may be lost.

- **Commit**
  - Finalizes the failover once you are satisfied with the DR state.
  - Cleans up unneeded recovery points.

- **Reprotect**
  - Starts replication in the **opposite direction** (from new primary to new secondary).
  - Required before you can **fail back**.

---

### Quick recap

For AZ‑104 level, you should be able to:

- Explain the three failover types (test, planned, unplanned).
- Walk through the steps of a **test failover** and **cleanup**.
- Describe what you do **after failover** (commit + reprotect).
- Understand how **recovery points** are chosen at failover time.

If you can draw the lifecycle on a whiteboard (protect → replicate → test failover → failover → commit → reprotect → failback), you’re ready for Site Recovery failover questions.

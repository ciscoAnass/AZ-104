
# Configure Azure Storage Redundancy

## A. Why redundancy matters

Azure Storage redundancy is about **keeping extra copies of your data** so that:

- A disk failure, rack failure, or even a **datacenter or regional outage** does not make you lose data.
- You can meet business **SLAs for durability and availability**.
- You can continue reading data even when part of Azure is down (if you use geo‑redundant options).

Redundancy is configured at the **storage account level** and applies to all services in that account (blobs, files, queues, tables) within the limits of each service.

**Exam focus**: You must be able to:

- Understand each redundancy option (LRS, ZRS, GRS, RA‑GRS, GZRS, RA‑GZRS).
- Choose the right option for a scenario (local vs zone vs geo).
- Know basic conversion possibilities (e.g., LRS → GRS, GRS → RA‑GRS).
- Understand impact on cost, durability, and access.

---

## B. Concepts: regions, availability zones, region pairs

Before redundancy types, recall:

- **Region** – a geographic location (e.g., West Europe).
- **Availability zone (AZ)** – independent datacenter within a region with distinct power/network.
- **Region pair** – Microsoft pairs regions (e.g., West Europe ↔ North Europe) for disaster recovery.

Redundancy options answer questions:

- How many copies of the data exist?
- Where are those copies stored? (same rack, multiple zones, secondary region)
- Are writes replicated **synchronously** (no data loss) or **asynchronously** (possible small RPO)?

---

## C. Redundancy options overview

### 1. LRS – Locally redundant storage

- **Copies:** 3 copies.
- **Where:** Single datacenter / stamp in one region.
- **Replication:** Synchronous.
- **Protection against:**
  - Disk/rack failures within that datacenter.
- **No protection against:** Datacenter outage, regional disaster.

Use when:

- Data can be re‑created from other sources or is not critical.
- Cost must be minimal.
- Compliance does **not** require cross‑zone or cross‑region replication.

---

### 2. ZRS – Zone‑redundant storage

- **Copies:** 3 copies.
- **Where:** Across **3 availability zones** in the same region.
- **Replication:** Synchronous.
- **Protection against:**
  - Disk/rack failures.
  - **Zone‑level** failures within a region.
- **No protection against:** Whole region outage.

Good for:

- Mission‑critical workloads that require high availability in a region with zones.
- When you need data to remain **available during a datacenter/zone failure** without regional failover.

Notes:

- Only available in **regions that support AZs**.
- Supported for GPv2 and some premium accounts; some combinations don’t support the Archive tier.

---

### 3. GRS – Geo‑redundant storage

- **Copies:** 3 copies in primary region (LRS) + 3 copies in paired secondary region.
- **Where:**
  - Primary region: LRS (3 copies in one datacenter).
  - Secondary region: LRS (3 copies in one datacenter in **paired region**).
- **Replication:** 
  - Within each region: synchronous.
  - Between primary and secondary region: **asynchronous**.
- **Primary access:** You can **read and write only in primary** region.
- **Secondary access:** Used only for **failover**; not readable by default.

Good for:

- Disaster recovery where you can tolerate some RPO (minor data loss) during a large outage.
- You want data automatically copied to another region, but you don't need regular read access from it.

---

### 4. RA‑GRS – Read‑access geo‑redundant storage

Same as GRS, **plus read access to secondary**.

- **Copies & locations:** Same as GRS.
- **Extra capability:** You can read from secondary region using `-secondary` endpoint:
  - Primary blob endpoint: `https://account.blob.core.windows.net`
  - Secondary blob endpoint: `https://account-secondary.blob.core.windows.net`
- Writes go to primary; secondary is read‑only replica.

Useful when:

- You need **read‑only failover** capabilities for DR.
- You want to offload some read workloads (e.g., analytics, reporting) to secondary region.

---

### 5. GZRS – Geo‑zone‑redundant storage

Combines **ZRS in primary region** with **LRS in secondary region**.

- **In primary region:** Data is stored across **3 availability zones** (ZRS).
- **In secondary region:** Data stored with LRS (3 copies in one datacenter).
- **Replication:**
  - Within primary: synchronous ZRS.
  - To secondary region: asynchronous.

GZRS protects against:

- Disk/rack failures.
- Zone failures in primary region.
- Regional disaster (via secondary region).

---

### 6. RA‑GZRS – Read‑access geo‑zone‑redundant storage

Same as GZRS, **plus read access to the secondary** region.

- Primary: ZRS.
- Secondary: LRS.
- Reads: from primary and from `-secondary` endpoint.
- Writes: only to primary.

Best for:

- **Highest availability and durability** with zone + geo redundancy.
- Apps that can read from secondary during incident or for reporting.

---

## D. Summary comparison table

(Simplified, exam‑focused)

| Option    | Region(s)          | Zones in primary | Read from secondary? | Typical use                             |
|----------|--------------------|------------------|----------------------|-----------------------------------------|
| LRS      | 1 region           | 0                | No                   | Low‑cost, non‑critical data             |
| ZRS      | 1 region           | Yes (3 zones)    | No                   | High availability in a single region    |
| GRS      | Primary + paired   | No (LRS each)    | No                   | DR across regions, no read from secondary |
| RA‑GRS   | Primary + paired   | No               | **Yes**              | DR + read from secondary                |
| GZRS     | Primary + paired   | Yes (primary)    | No                   | Zone + geo redundancy, write to primary |
| RA‑GZRS  | Primary + paired   | Yes (primary)    | **Yes**              | Highest availability + geo read access  |

**Exam tip**

If the scenario mentions:

- **“Survive region failure”** → choose a **geo‑redundant** option (GRS, RA‑GRS, GZRS, RA‑GZRS).
- **“Survive zone failure but not necessarily region”** → **ZRS** (or GZRS if also region DR).
- **“Need to read from secondary region”** → **RA‑GRS** or **RA‑GZRS**.
- **“Cheapest”** → **LRS**.

---

## E. Redundancy and service‑specific notes

### 1. Azure Files

- Azure Files geo‑redundancy (GRS/GZRS) is available only for certain file share types and regions.
- Premium file shares (SSD) often only support **LRS or ZRS**, not GRS.
- For some compliance scenarios, you may need replication at application level for premium shares.

### 2. Access tiers & redundancy

- Not all redundancy options support all blob access tiers:
  - Archive tier is not supported in all ZRS/GZRS/RA‑GZRS combinations.
- When changing redundancy, you must ensure:
  - New redundancy supports current features (tiers, protocols).

---

## F. Changing redundancy after creation

You can often change redundancy **without recreating** the storage account, but there are rules:

Typical allowed changes (subject to region/service limits):

- **LRS → GRS → RA‑GRS** (and back from RA‑GRS → GRS).
- **LRS → ZRS** in some regions.
- **GRS/RA‑GRS → GZRS/RA‑GZRS** where supported.

Constraints (high‑level, exam‑style):

- Some transitions are **one‑way** and may require migration (e.g., GZRS → ZRS or back to LRS may need copy).
- You cannot change the **paired region**; that is fixed for each Azure region.
- When using **Archive tier**, you may need to rehydrate archived blobs before switching to a redundancy that doesn’t support Archive.

How to change redundancy:

- Portal: Storage account → **Configuration** → **Replication** setting.
- CLI:

  ```bash
  az storage account update \
    --name mystorageacc \
    --resource-group rg1 \
    --sku Standard_GRS
  ```

Where `sku` indicates redundancy:

- `Standard_LRS`
- `Standard_ZRS`
- `Standard_GRS`
- `Standard_RAGRS`
- `Standard_GZRS`
- `Standard_RAGZRS`
- `Premium_LRS` (premium).

---

## G. Reading from the secondary and failover

### 1. Accessing secondary endpoint (RA‑GRS / RA‑GZRS)

- Blobs: `https://account-secondary.blob.core.windows.net`
- Tables: `https://account-secondary.table.core.windows.net`
- Queues: `https://account-secondary.queue.core.windows.net`
- Files: some services may not expose secondary endpoint.

You must design your app to:

- Switch to the `-secondary` endpoint when the primary is unavailable.
- For **read‑only** workloads (reports/analytics), directly use `-secondary` to reduce primary load.

### 2. Geo‑failover

If the primary region is lost for a long time, Microsoft or you might initiate a **storage account failover**:

- Secondary region becomes **new primary**.
- DNS endpoints are updated so `https://account.blob.core.windows.net` now points to previously secondary region.
- After failover:
  - Previous primary may not be recoverable.
  - Some data written shortly before failure might not have been replicated (asynchronous replication).
  - You might need to reconfigure your DR setup.

**Exam tip**

- GRS/GZRS alone **do not** give read access to secondary – you only get failover.
- RA‑GRS/RA‑GZRS provide **read access** to secondary before failover.

---

## H. Choosing the right redundancy – scenario guide

Think in terms of **risk, cost, and RPO/RTO**:

1. **Low‑risk data, can be recreated, cost‑sensitive**  
   → **LRS**

2. **Business‑critical app, cannot go down if one datacenter/zone fails, but region outage is rare**  
   → **ZRS**

3. **Need regional disaster protection but do not need read access to secondary**  
   → **GRS** or **GZRS**  
   - If you also want local zone protection in primary, choose **GZRS**.

4. **Need regional disaster protection AND want to read from secondary**  
   → **RA‑GRS** or **RA‑GZRS**  
   - For highest availability (zones + geo + secondary read), choose **RA‑GZRS**.

5. **Very strict compliance / mission critical**  
   - Consider **RA‑GZRS** plus application‑level backups / snapshots.

---

## I. Exam patterns to remember

- **Keyword “zone failure”** → **ZRS** or **GZRS/RA‑GZRS**.
- **Keyword “regional outage / DR / second region”** → **GRS** family.
- **Keyword “read-only access from secondary region”** → **RA‑GRS / RA‑GZRS**.
- **Keyword “lowest cost, not critical”** → **LRS**.

If you can describe **what each redundancy option protects you from** and **when to use it**, you will be well prepared for this part of AZ‑104.

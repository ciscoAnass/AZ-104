
# Configure Object Replication for Block Blobs

## A. What is object replication?

**Object replication** for Azure Blob Storage is a feature that **asynchronously copies block blobs** from a **source storage account/container** to a **destination account/container**, according to rules you define.

Key characteristics:

- Works only with **block blobs**.
- Copies **new** blob versions (and, optionally, existing ones) from source to destination.
- Uses a **replication policy** with one or more **replication rules**.
- Replication happens **asynchronously** – not real‑time, but usually fast.
- Source and destination can be:
  - Same region or different regions.
  - Same subscription or different subscriptions.
  - Same tenant or (optionally) different tenants, depending on configuration.

Why use it?

- **Disaster recovery** beyond account‑level redundancy.
- **Data locality** – keep a copy of your blobs nearer to specific users or services.
- **Compliance** – maintain a read‑only replica somewhere else.
- **Analytics** – replicate production blobs to another account for analytics jobs.

---

## B. Prerequisites and limitations

Object replication is powerful but strict. For AZ‑104 you must know **what is required**.

### 1. Supported account types

Object replication supports:

- **General‑purpose v2 (StorageV2)** accounts.
- **Premium block blob** accounts.

It does **not** support:

- Classic storage accounts.
- GPv1 accounts.
- Accounts with **hierarchical namespace** (Data Lake Gen2) enabled at the time of writing.

### 2. Required features

To use object replication:

1. **Blob versioning** must be enabled:
   - Enabled on **source and destination** accounts.
2. **Change feed** must be enabled:
   - Enabled on the **source** account.

Why?

- Versioning keeps a history of blob changes.
- Change feed provides a log of changes that object replication reads to know what to copy.

If these are not configured, replication **won’t work**.

---

### 3. Data types and operations supported

- Only **block blobs** are replicated.
- Snapshots and some special operations have limitations.
- Replicated items:
  - Blob data
  - Blob metadata
  - Blob tags
- Operations that are replicated:
  - Create / upload (new blob versions)
  - Update
  - Delete (if configured)

### 4. Supported topologies

You can configure:

- **One‑way** replication: Account A → Account B.
- **Many‑to‑one**: A, B, C → D (each with its own policy).
- **One‑to‑many**: A → B, C (multiple policies).
- **Bidirectional** replication (A ↔ B) using two policies (careful – avoid loops by using versioning rules properly).

### 5. Cross‑tenant replication

- Object replication can work **across tenants**, but you can also **block cross‑tenant replication** via a property on the account (for security/compliance).
- For the exam, remember: **tenants, subscriptions, and resource groups can differ**, but permissions & policies must be set correctly.

---

## C. How object replication works (high level)

1. You create a **replication policy** between a **source** and a **destination** storage account.
2. The policy contains one or more **rules**, each rule defines:
   - Source container.
   - Destination container.
   - Optional prefix filters and minimum creation time.
3. Azure Storage uses the **change feed** on the source to detect changes:
   - New blob versions.
   - Deletes (if included).
4. For each eligible change, Azure Storage:
   - Creates an equivalent blob version in the destination container.
   - Copies metadata, properties, and tags.
5. Replication is **eventually consistent**:
   - There is a delay between the write on source and appearance on destination.

If the destination has an **immutability policy** preventing a change, replication of that specific operation may fail, but other blobs continue to replicate.

---

## D. Security & permissions

To configure object replication, you need:

- Sufficient **Azure RBAC** permissions on both accounts:
  - Typically **Contributor** or **Owner** on both storage accounts.
- If accounts are in different subscriptions/tenants:
  - Proper cross‑tenant access and trust.

Object replication itself uses **Azure Storage internal identity**, not your user identity, to perform replication; once configured, it runs automatically.

---

## E. Configuring object replication – Azure portal

### Step 1 – Prepare accounts

For both source and destination accounts:

1. Ensure account type is **StorageV2** or **Premium BlockBlobStorage**.
2. Ensure **hierarchical namespace is disabled** (no Data Lake Gen2).
3. Configure networking so that the accounts can be accessed (consider firewalls, private endpoints, etc.).

### Step 2 – Enable versioning and change feed

On **source account**:

- Go to **Data protection**:
  - Enable **Blob versioning**.
  - Enable **Change feed**.
  - (Optional but recommended) Enable **soft delete** for blobs.

On **destination account**:

- Enable **Blob versioning** (change feed not required on destination, but harmless if on).

### Step 3 – Configure object replication in portal

1. In the **source storage account**, go to **Data management → Object replication**.
2. Select **Create replication rules**.
3. Choose:
   - Destination subscription.
   - Destination storage account.
4. In **Container pair details**:
   - Select **source container**.
   - Select **destination container** (you can create a new one).
   - Decide whether to:
     - Replicate only new blobs from now on, or
     - Also replicate **existing blobs** (this may take longer and cost more).
5. Optionally, specify:
   - **Prefix filters** (e.g., only replicate blobs with name starting with `logs/`).
   - **Minimum creation time** (replicate only blobs created after X date/time).
6. Review and **create** the policy.

When you create a policy via portal:

- A **policy** is created on the destination account (with a generated policy ID).
- The same policy is linked back to the source account by ID automatically.

You can monitor replication status:

- Under **Object replication** blade on each storage account.
- With metrics/logs for replication latency and errors.

---

## F. Configuring object replication – Azure CLI (outline)

### 1. Create a replication policy

Typical flow:

1. Define a **JSON policy file** describing:
   - Source and destination account IDs.
   - Rules: source/destination containers, prefix filters, min creation time.
2. Use `az storage account or-policy create` on the **destination** account.
3. Then use `az storage account or-policy show` to retrieve the policy ID.
4. Link the policy to the **source** account with the same policy ID.

Example (simplified):

**policy.json**

```json
{
  "properties": {
    "sourceAccount": "/subscriptions/<sub-id>/resourceGroups/<rg>/providers/Microsoft.Storage/storageAccounts/srcaccount",
    "destinationAccount": "/subscriptions/<sub-id>/resourceGroups/<rg>/providers/Microsoft.Storage/storageAccounts/destaccount",
    "rules": [
      {
        "ruleId": "rule1",
        "sourceContainer": "src-container",
        "destinationContainer": "dest-container",
        "filters": {
          "prefixMatch": [ "logs/", "images/" ],
          "minCreationTime": "2025-01-01T00:00:00Z"
        }
      }
    ]
  }
}
```

**Create policy on destination**

```bash
az storage account or-policy create \
  --resource-group destRG \
  --account-name destaccount \
  --policy @policy.json
```

Get the policy ID:

```bash
az storage account or-policy list \
  --resource-group destRG \
  --account-name destaccount
```

Note the `policyId`, then associate the same policy with the source account:

```bash
az storage account or-policy update \
  --resource-group srcRG \
  --account-name srcaccount \
  --policy-id <policyId> \
  --policy @policy.json
```

### 2. Manage rules in a policy

You can use:

- `az storage account or-policy rule add`
- `az storage account or-policy rule list`
- `az storage account or-policy rule remove`
- `az storage account or-policy rule update`

Example – add a rule:

```bash
az storage account or-policy rule add \
  --resource-group destRG \
  --account-name destaccount \
  --policy-id <policyId> \
  --source-container src-container \
  --destination-container dest-container \
  --min-creation-time "2025-01-01T00:00:00Z"
```

---

## G. Object replication vs account redundancy

Important: **Object replication is different from redundancy (LRS/ZRS/GRS/…)**.

| Feature                  | Object replication                          | Account redundancy (GRS, etc.)                 |
|--------------------------|---------------------------------------------|------------------------------------------------|
| Scope                    | Selected containers / prefixes              | Entire storage account                         |
| Control                  | You choose what to replicate                | Azure replicates all data at account level     |
| Access to secondary      | Destination is a normal storage account     | Secondary region access only with RA‑* options |
| Configuration            | Policies + rules                            | Replication setting in account configuration   |
| Common use               | Application‑level DR, data locality, ETL    | Infrastructure‑level DR and durability         |

For exam questions:

- If the requirement is **“replicate all data to paired region automatically”** → think **GRS/GZRS**.
- If the requirement is **“only replicate specific containers/prefixes”** or **“between arbitrary accounts/regions/subscriptions”** → think **object replication**.

---

## H. Troubleshooting & monitoring

Common issues:

1. **Prerequisites not enabled**
   - Check that versioning and change feed are enabled correctly.
2. **Permissions**
   - Ensure your account has Contributor or higher on both storage accounts.
3. **Network restrictions**
   - If accounts use private endpoints or strict firewalls, ensure replication path is allowed.
4. **Immutability policies**
   - Destination blobs with immutable policies may prevent certain operations being replicated.

Monitoring:

- Use the **Object replication** blade in Portal to see:
  - Policy health
  - Latency
  - Error counts
- Use **Azure Monitor metrics and logs** for deeper insights.

---

## I. Exam tips and typical questions

1. **“You need to replicate only a subset of blob data (e.g., container X, prefix ‘images/’) to another region for analytics, without exposing the production account.”**  
   → Use **object replication** with a replication policy and rules.

2. **“You need to keep two storage accounts in sync across subscriptions for DR, but only for specific containers.”**  
   → Again, **object replication** (account redundancy options are all‑or‑nothing).

3. **“Which features must be enabled before configuring object replication?”**  
   → **Blob versioning (both accounts)** and **change feed (source)**.

4. **“Does object replication work with Data Lake Gen2 (hierarchical namespace)?”**  
   → At the time of writing, **no** – not supported.

5. **“Is replication synchronous or asynchronous?”**  
   → **Asynchronous** – there may be a delay between write on source and appearance on destination.

If you can:

- Explain how object replication works.
- List the prerequisites and limitations.
- Describe the difference between object replication and GRS/RA‑GRS/GZRS/RA‑GZRS.

…you will be ready for object replication questions in AZ‑104.

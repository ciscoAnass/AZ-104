# Configure Azure Storage Firewalls and Virtual Networks

## A. Goal of this topic

For AZ-104, you must be able to:

- **Lock down a storage account** so only specific networks can access it.
- Combine **IP rules**, **virtual networks**, **resource instance rules**, and **trusted Azure services**. citeturn0search0turn0search10turn0search17  
- Understand the impact of **default public network access** settings. citeturn0search5turn0search15

In real life, this is how you stop “anyone on the internet with a key/SAS” from reaching your data. The network layer is a **second line of defense** after authentication.

---

## B. Data plane vs control plane

**Important concept for the exam:**

- **Control plane** = management operations (create storage account, set properties, IAM, policies).  
- **Data plane** = read/write/list/delete blobs, files, queue messages, table entities.

**Azure Storage firewall rules apply to the data plane only.** citeturn0search20

- You can still manage the storage account (control plane) through Azure Resource Manager even when data plane access is restricted, as long as you have proper RBAC.
- Tools like **Azure Storage Explorer**, **AzCopy**, or **Portal data blades** must originate from an allowed network to access **data**. citeturn0search20

---

## C. Public network access: default behavior

By default, when you create a Storage account:

- **Public network access** is set to **allow from all networks** – any IP on the internet can reach the endpoint, but still needs authentication (keys, SAS, Entra). citeturn0search5turn0search10

You can change the default action to:

1. **Allow**  
   - Accept traffic from **all networks**.

2. **Deny**  
   - Block all traffic by default; only allow what matches **explicit network rules** (VNets, IPs, resource instances, trusted services). citeturn0search5turn0search15turn0search17

In the portal, these options are usually shown as:

- **Enabled from all networks**  
- **Enabled from selected virtual networks and IP addresses**  
- **Disabled** (no public network access – typically when using only private endpoints)

> **Exam tip:** If the scenario says “storage must NOT be reachable from the internet but still must be accessible from specific Azure VNets,” choose **Selected networks** with **default action = Deny** and add VNet rules. citeturn0search5turn0search10turn0search15

---

## D. Network rules: the building blocks

When default action is **Deny**, you open access with **network rules**. There are four types: citeturn0search0turn0search17

1. **IP network rules**
2. **Virtual network rules**
3. **Resource instance rules**
4. **Trusted Azure services** (exceptions)

### 1. IP network rules

- Allow requests from **specific public IP addresses or ranges** (CIDR). citeturn0search0turn0search17  
- Used mainly for:
  - On-premises networks exposed via public IP.
  - Developers working from known IPs (office, VPN).

Limits (per storage account): citeturn0search17

- Up to **400 IP network rules**.

**Example:**

- Allow only `52.168.10.0/24` and `40.67.90.10` to access the account.
- All other IPs are blocked at the firewall, even if they have keys or SAS.

### 2. Virtual network (VNet) rules

- Allow traffic from **specific subnets in Azure VNets**.  
- VNet must be in the **same region** as the storage account (for service endpoints). citeturn0search15turn0search0  
- Often configured together with **service endpoints** or **private endpoints**:

  - **Service endpoints**: extend your VNet identity to the storage service’s public endpoint.  
  - **Private endpoints**: map the storage account to a private IP in your VNet (Private Link).

Limits: up to **400 VNet rules** per storage account. citeturn0search17

**Example scenario:**

> “Only allow an app running in subnet `vnet-app/subnet-backend` to access blob storage. Block other internet clients.”  

Solution outline:

1. Set default action to **Deny**. citeturn0search5turn0search15  
2. Add a **virtual network rule** for the `subnet-backend`.  
3. Enable the **Microsoft.Storage service endpoint** for that subnet (if using service endpoints). citeturn0search15turn0search0  

### 3. Resource instance rules

- Allow access from specific **Azure resource instances** that can’t be fully isolated via VNet or IP, such as certain PaaS services. citeturn0search0  
- Example: Allow a specific **Azure Synapse workspace, Azure Machine Learning workspace, or Azure App Service** instance.

Limits: up to **200 resource instance rules** per storage account. citeturn0search17

**Exam angle:**

If the question says:

> “Allow only a specific Azure service instance to access this storage account, without opening it to the entire subnet,”

think **resource instance rule**, not just VNet rule.

### 4. Trusted Azure services

- Option to **“Allow trusted Microsoft services to access this storage account”**. citeturn0search0turn0search20  
- Lets certain Microsoft services bypass network rules when accessing your account, but only from Microsoft-managed infrastructure.
- Examples (varies by service): Azure Backup, Site Recovery, Azure Monitor, etc.

Use with care: it’s convenient but slightly broad. Combine with least-privilege auth (managed identity / SAS) on top.

---

## E. Private endpoints (Private Link) – big picture

Even though **“Configure private endpoints”** is covered later under networking, you must understand its relationship to **storage access**:

- A **private endpoint** = a network interface with a **private IP in your VNet** that represents your Storage account.  
- Clients access `mystorageaccount.privatelink.blob.core.windows.net` via this private IP.  
- Traffic stays on the Microsoft backbone; the public endpoint can be disabled.

Limits: up to **200 private endpoints** per storage account. citeturn0search17

Common pattern:

- **Public network access: Disabled** (no internet).  
- Only clients in allowed VNets via **private endpoints** can reach the account.

> **Exam tip:** If the requirement includes “no traffic over the public internet” or “strictly private connectivity,” the answer usually involves **Private Link / private endpoints**, not just firewall IP rules. citeturn0search0turn0search17

---

## F. How to configure in the Azure portal

High-level steps (Blob/File/Queue/Table all share the same account-level network settings):

1. Go to **Storage account → Networking**. citeturn0search5turn0search10  
2. Under **Public network access**:
   - Choose **Enabled from selected virtual networks and IP addresses** (to restrict) or **Disabled** (to rely only on private endpoints).  
3. Configure **network rules**:
   - **Virtual networks** tab → Add VNet/subnet (and service endpoint if required). citeturn0search15turn0search0  
   - **IP networks** tab → Add IP or ranges. citeturn0search0turn0search17  
   - **Resource instances** tab → Add resource type and instance. citeturn0search0turn0search17  
4. (Optional) Enable **“Allow trusted Microsoft services to access this storage account”**. citeturn0search0turn0search20  
5. (Optional) Configure **Private endpoints** on the **Private endpoint connections** tab.

---

## G. How to configure with Azure CLI / PowerShell

### 1. Set default action

```bash
# Deny by default (only allowed networks can access)
az storage account update \
  --resource-group myrg \
  --name mystorageaccount \
  --default-action Deny
```

```bash
# Allow all networks
az storage account update \
  --resource-group myrg \
  --name mystorageaccount \
  --default-action Allow
```
citeturn0search5turn0search15

### 2. Add an IP rule

```bash
az storage account network-rule add \
  --resource-group myrg \
  --account-name mystorageaccount \
  --ip-address 52.168.10.0/24
```

### 3. Add a virtual network rule (CLI equivalent)

```bash
az storage account network-rule add \
  --resource-group myrg \
  --account-name mystorageaccount \
  --vnet-name myvnet \
  --subnet mysubnet
```

Or in PowerShell (conceptually): citeturn0search15

```powershell
$subnet = Get-AzVirtualNetwork -ResourceGroupName "myrg" -Name "myvnet" |
          Get-AzVirtualNetworkSubnetConfig -Name "mysubnet"

Add-AzStorageAccountNetworkRule `
  -ResourceGroupName "myrg" `
  -Name "mystorageaccount" `
  -VirtualNetworkResourceId $subnet.Id
```

### 4. Remove a network rule

```powershell
Remove-AzStorageAccountNetworkRule `
  -ResourceGroupName "myrg" `
  -Name "mystorageaccount" `
  -VirtualNetworkResourceId $subnet.Id
```
citeturn0search15

You do not need to memorize exact syntax for the exam, but you must recognize what **changing `--default-action`** and adding **network rules** achieves.

---

## H. Common scenarios and how to think through them

### Scenario 1 – Restrict to on-premises IP range

> “Only allow requests from on-premises network with public IP 40.112.50.0/24.”

- Set **default action = Deny**. citeturn0search5turn0search10  
- Add **IP network rule** for `40.112.50.0/24`. citeturn0search0turn0search17

### Scenario 2 – Only an app in a specific subnet can access blobs

> “VMs in `app-vnet/subnet-web` should be able to access Blob storage. Nothing else should.”

- Enable **service endpoint** `Microsoft.Storage` on subnet `subnet-web`. citeturn0search0turn0search15  
- Set **default action = Deny**.  
- Add **VNet rule** for that subnet only.

### Scenario 3 – Use private endpoints, no internet access

> “The storage account must not be reachable from the internet, only from workloads in `vnet-prod`.”

- Disable public access (or set public network access to **Disabled**). citeturn0search5turn0search10  
- Create **private endpoints** for Blob/File/Queue/Table as needed in `vnet-prod`. citeturn0search17  
- Ensure DNS resolves to the private endpoint IPs (privatelink zone).

### Scenario 4 – Allow Synapse workspace only, not full subnet

> “An Azure Synapse workspace in the same region needs to access data, but you don’t want to open to all of its subnet.”

- Use a **resource instance rule** for that specific Synapse workspace. citeturn0search0turn0search17  
- Keep default action on **Deny**.

---

## I. Exam takeaways

- **Firewall rules are data plane only.** Control plane is managed via ARM and RBAC. citeturn0search20  
- **Default behavior** is “allow from all networks” until you change it. citeturn0search5turn0search10  
- To secure storage:
  - Change default to **Deny**.  
  - Add **IP**, **VNet**, **resource instance**, and **trusted service** rules as needed. citeturn0search0turn0search17turn0search20  
- Use **Private Link** when the requirement is **no public internet traffic**. citeturn0search17  
- Remember the limits: 400 IP rules, 400 VNet rules, 200 resource instance rules, 200 private endpoints per storage account. citeturn0search17

If you can read a scenario and immediately decide whether to use **IP rules**, **VNet rules**, **resource instance rules**, or **private endpoints**, you are in very good shape for this part of AZ-104.
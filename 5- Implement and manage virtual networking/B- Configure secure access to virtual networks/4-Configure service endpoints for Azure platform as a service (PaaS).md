# Configure service endpoints for Azure platform as a service (PaaS)

_AZ-104 exam objective: Configure service endpoints to secure access from a virtual network to Azure PaaS services._

---

## 1. What are virtual network service endpoints?

Many Azure PaaS services (Storage, SQL Database, Cosmos DB, Key Vault, etc.) are **multi-tenant services** that by default are reachable over **public IP addresses** on the Internet.

Even if your VM is in a private subnet, traffic to these services normally goes to a **public endpoint**.

**Virtual network service endpoints** let you:

- Extend your VNet’s **private address space and identity** to the PaaS service.
- Force traffic from your subnet to the PaaS service to travel over the **Azure backbone**, not the public Internet.
- Restrict the PaaS resource so that **only traffic from specific VNets/subnets** is allowed.

> Important: Service endpoints do **not** give the service a private IP in your VNet. The service still has a public endpoint, but access can be limited to your VNet/subnet.

---

## 2. How service endpoints work (conceptually)

Consider this scenario:

```text
VNet 10.0.0.0/16
  └─ Subnet snet-app 10.0.1.0/24 (with a VM)
Azure Storage Account: mystorage001 (public endpoint)
```

Without service endpoints:

- VM in `snet-app` connects to `mystorage001.blob.core.windows.net` over the Internet (public IP).
- If you configure a firewall on the storage account, you might allow certain public IPs only.

With service endpoints enabled:

1. On subnet `snet-app`, you **enable a service endpoint** for `Microsoft.Storage`.
2. On the storage account firewall, you **allow** access from `VNet / subnet` (network rule).
3. When the VM connects, Azure recognizes the source as from that VNet/subnet and sends it over the **Azure backbone**.
4. You can optionally **deny all other Internet access** to that storage account.

**Key benefit:** You can say
> “Only this subnet can talk to this storage account; everyone else is blocked, even from the Internet.”

---

## 3. Supported services (high level)

Common PaaS services that support service endpoints (selection, not exhaustive):

- **Azure Storage** (`Microsoft.Storage`)
- **Azure SQL Database** (`Microsoft.Sql`)
- **Azure Cosmos DB**
- **Azure Key Vault**
- Some others (Event Hubs, Service Bus, etc.)

For AZ‑104, you mainly need to recognize that **Storage** and **SQL** are classic examples.

---

## 4. Enabling a service endpoint on a subnet

### 4.1 In the Azure portal

1. Go to **Virtual networks** → select your VNet.
2. Go to **Subnets** → choose the subnet (e.g. `snet-app`).
3. Scroll to **Service endpoints**.
4. Select the service(s) you want, for example:
   - `Microsoft.Storage`
   - `Microsoft.Sql`
5. Click **Save**.

This updates the subnet so that traffic from it to those services is treated as coming from the VNet.

### 4.2 Using Azure CLI

```bash
az network vnet subnet update   --resource-group rg-app   --vnet-name vnet-app   --name snet-app   --service-endpoints Microsoft.Storage Microsoft.Sql
```

You can add multiple service endpoints for different services if needed.

---

## 5. Restricting access on the PaaS resource (firewall / network rules)

Enabling a service endpoint on the subnet is only half of the configuration.  

You must also configure **network rules on the PaaS service** to restrict access to that VNet/subnet.

### 5.1 Example: Azure Storage account

Goal: Only allow access to `mystorage001` from `snet-app` in `vnet-app`.

**Step 1 – Enable service endpoint on subnet** (see section 4).

**Step 2 – Configure storage account network rules**

1. Go to **Storage accounts** → `mystorage001`.
2. Go to **Networking**.
3. Under **Public network access**, choose:
   - **Enabled from selected virtual networks and IP addresses**.
4. Under **Virtual networks**, click **+ Add existing virtual network**.
5. Select:
   - Subscription
   - Virtual network: `vnet-app`
   - Subnet: `snet-app`
6. Save the configuration.

Now the storage account only allows traffic from:

- Selected VNets/subnets with service endpoints enabled.
- Any specific public IPs you added (if configured).

All other traffic is **denied**.

### 5.2 Using Azure CLI (Storage example)

```bash
# Add VNet/subnet rule to storage account
az storage account network-rule add   --resource-group rg-app   --account-name mystorage001   --vnet-name vnet-app   --subnet snet-app
```

You can also manage IP-based rules, but the key concept is **VNet-based access using service endpoints**.

---

## 6. Service endpoints vs private endpoints (quick comparison)

Service endpoints and private endpoints are often compared. For AZ‑104 you should know the difference.

| Feature               | Service Endpoints                                   | Private Endpoints (Private Link)                         |
|----------------------|-----------------------------------------------------|---------------------------------------------------------|
| IP type              | Uses **public IP** of the PaaS service              | PaaS appears as a **private IP** in your subnet         |
| Network path         | Azure backbone, but to a public endpoint            | Azure backbone, to a **private endpoint NIC**           |
| Access control       | VNet/subnet-based ACLs on the PaaS firewall         | Access via private endpoint; can **disable public access** |
| DNS changes          | Usually none (still use public FQDN)                | Needs DNS to resolve service name to private IP         |
| Complexity           | Simpler                                             | More complex but more isolation                         |
| On-prem integration  | On-prem → VNet → PaaS via public endpoint (still public) | On-prem → VNet → PaaS via private IP                    |

**Rule of thumb for AZ‑104:**

- Use **service endpoints** when you want **simpler** VNet-based restriction to PaaS, and you’re fine with the service still having a **public endpoint**.
- Use **private endpoints** when you need **maximum network isolation** and **private IP** access to PaaS.

---

## 7. Common design patterns

### 7.1 Secure Storage access from app subnet only

```text
VNet: vnet-app
  └─ Subnet: snet-app  (service endpoint: Microsoft.Storage)

Storage account: mystorage001
  └─ Firewall: allow only vnet-app/snet-app
```

Effect:

- **Only VMs/function apps in `snet-app`** can access `mystorage001`.
- Even if someone knows the storage account name and key, traffic from other networks is blocked (unless allowed explicitly).

### 7.2 Secure SQL Database access from web app subnet

```text
VNet: vnet-web
  └─ Subnet: snet-web (service endpoint: Microsoft.Sql)

Azure SQL Server: sql-hospital.database.windows.net
  └─ Firewall: allow vnet-web/snet-web
```

- Only resources in `snet-web` can connect to the SQL Database.
- Access from random Internet addresses will be denied.

---

## 8. Limitations and considerations

- Service endpoints are **configured per subnet and per service** (e.g. `Microsoft.Storage`).
- Service endpoints don’t work from **on-premises networks directly**:
  - On-premises traffic still hits the service’s **public endpoint**.
  - To restrict on-premises, you generally use IP firewall rules.
- Some services require the VNet and PaaS resource to be in the **same region** (check documentation; Storage and SQL are common examples).
- Service endpoints are **free** (no additional charge), but traffic charges still apply as usual.
- Once you enable a service endpoint on a subnet, the **source IP seen by the service changes** from public IP to **VNet private IP** identity. This can break firewall rules that rely on old public IPs.

---

## 9. AZ‑104 exam tips

- Know that **service endpoints**:

  - Are configured on **subnets**.
  - Allow you to restrict PaaS resources to **specific VNets/subnets**.
  - Keep traffic on the **Azure backbone** network.

- Typical question forms:
  - “You need to restrict an Azure Storage account so only a specific subnet can access it.”  
    → Answer: **Enable service endpoints for Microsoft.Storage on that subnet** and configure the storage firewall to allow only that VNet/subnet.
  - “You want to secure an Azure SQL Database from the Internet but still allow access from your VNet.”  
    → Answer: **Use service endpoints** (or private endpoints; pick based on wording about private IP vs public).

- If the requirement includes phrases like **“private IP address in the VNet”** or **“disable all public access”**, that usually points to **private endpoints**, not service endpoints.

If you understand when and how to use service endpoints to limit access to PaaS, you’ve covered this part of the AZ‑104 blueprint.

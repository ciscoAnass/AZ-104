# Configure private endpoints for Azure PaaS

_AZ-104 exam objective: Configure private endpoints to securely access Azure PaaS services from virtual networks._

---

## 1. What is a private endpoint?

A **private endpoint** is a **network interface (NIC)** in your VNet with a **private IP address** that connects securely to a PaaS service using **Azure Private Link**.

Key points:

- The PaaS service (Storage, SQL, Key Vault, etc.) appears as if it lives **inside your VNet**.
- Traffic between your VNet and the PaaS service travels over the **Azure backbone**, not the public Internet.
- You can **disable public network access** to the service and force all access via private endpoints.

> Think of a private endpoint as a **“private door”** from your subnet directly into an Azure service.

---

## 2. Private endpoints vs service endpoints

These two features are often mentioned together. Make sure you can tell them apart.

| Feature            | Service Endpoints                                      | Private Endpoints (Private Link)                              |
|-------------------|--------------------------------------------------------|----------------------------------------------------------------|
| IP type           | Service still has a **public IP**                      | Service is accessible via a **private IP in your subnet**      |
| Resource in VNet? | No – service remains outside the VNet                  | Appears like it’s inside your VNet via a private NIC           |
| Security control  | VNet/subnet rules on the service firewall              | Access bound to specific private endpoint(s)                   |
| DNS               | Usually same public DNS name, no change required       | Requires DNS to resolve service name to the **private IP**     |
| Public access     | Can restrict to selected VNets/IPs but public endpoint still exists | Can **disable public network access** entirely               |
| Complexity        | Simpler                                                | More configuration (private DNS, endpoints per resource)       |

**Rule of thumb:**

- If requirement = “Use **private IP** from VNet / disable all public access to PaaS”, you need **private endpoints**.
- If requirement = “Restrict PaaS to VNet/subnet but okay with public endpoint existing”, **service endpoints** are enough.

---

## 3. How private endpoints work

### 3.1 Basic flow

Example with Azure Storage:

```text
VNet: vnet-app 10.0.0.0/16
  └─ Subnet: snet-private 10.0.1.0/24
        └─ Private endpoint NIC: 10.0.1.10 (for mystorage001)

Storage account: mystorage001
```

Steps:

1. You create a **private endpoint** in `snet-private` pointing to `mystorage001`.
2. Azure creates a **network interface** (NIC) in that subnet with a private IP (e.g. `10.0.1.10`).
3. DNS is configured (using Private DNS Zones) so that:
   - `mystorage001.blob.core.windows.net` resolves to `10.0.1.10` for workloads inside the VNet.
4. When a VM in `snet-private` accesses the blob endpoint, traffic goes to `10.0.1.10` and then travels over **Private Link** to `mystorage001`.

You can now set the storage account’s **public network access = Disabled**, so only the private endpoint can reach it.

---

## 4. DNS with private endpoints (very important)

Private endpoints rely heavily on **DNS**.

When you create a private endpoint, Azure can automatically create **Private DNS zone** records such as:

- `privatelink.blob.core.windows.net`
- `privatelink.database.windows.net`
- etc., depending on the service.

Typical DNS pattern:

1. You have a public FQDN for the service, e.g.:
   - `mystorage001.blob.core.windows.net`
2. Inside your VNet, DNS is configured so that this name resolves to a **CNAME** pointing to a `privatelink` zone, which in turn points to the private IP of the endpoint.

For AZ‑104, you don’t need to memorize exact DNS record types, but you must know:

- If DNS is not configured correctly, clients might still resolve the **public IP** instead of the private IP.
- Best practice is to use **Private DNS zones** linked to the VNet.

### 4.1 Portal workflow for DNS

When creating a private endpoint in the portal, you often see:

- Option to **Integrate with private DNS zone**.
- You can choose to create a new private DNS zone (for example `privatelink.blob.core.windows.net`) and link it to the VNet.
- Azure then manages the A records pointing to the private endpoint IP.

If you use your own DNS servers:

- You must configure them to forward or host the relevant zones so that the service name resolves to the **private IP**.

---

## 5. Creating a private endpoint in the portal

Let’s use **Azure Storage** as the example.

### 5.1 Prerequisites

- A **VNet** and subnet where the private endpoint NIC will live.
- A **PaaS resource**, e.g. Storage account `mystorage001`.
- Permissions to create private endpoints and private DNS zones.

### 5.2 Step-by-step

1. Go to the **Storage account** `mystorage001` in the portal.
2. In the left menu, go to **Networking**.
3. In the **Private endpoint connections** tab, click **+ Private endpoint**.
4. On the **Basics** tab:
   - Subscription, Resource group
   - Name: `pe-mystorage001`
   - Region: must match the region of your VNet (and usually the storage account region).
5. On the **Resource** tab:
   - Connection method: **Connect to an Azure resource in my directory**.
   - Resource type: `Microsoft.Storage/storageAccounts`.
   - Resource: `mystorage001`.
   - Target sub-resource (GroupId): `blob` (for blob storage), or `file`, etc.
6. On the **Virtual network** tab:
   - Select your VNet: `vnet-app`.
   - Select subnet: `snet-private`.
7. **Integrate with private DNS zone**:
   - Choose **Yes** (recommended).
   - Create or select a private DNS zone: e.g. `privatelink.blob.core.windows.net`.
   - Ensure it is linked to `vnet-app`.
8. Review + create → **Create**.

After deployment:

- A NIC with a private IP exists in `snet-private`.
- The storage account now shows a **private endpoint connection**.
- DNS inside the VNet resolves the storage endpoint name to the private IP.

### 5.3 Disable public network access (for higher security)

To ensure traffic uses **only the private endpoint**:

1. Go to `mystorage001` → **Networking**.
2. Under **Public network access**, select **Disabled**.
3. Save.

Now, even if someone tries to connect from public Internet, they will be blocked. Only traffic via the private endpoint is allowed.

---

## 6. Creating private endpoints with Azure CLI

Example: private endpoint for a Storage account’s blob endpoint.

```bash
# Variables
RG="rg-app"
VNET="vnet-app"
SUBNET="snet-private"
STORAGE="mystorage001"
PE_NAME="pe-mystorage001"

# Create private endpoint
az network private-endpoint create   --resource-group $RG   --name $PE_NAME   --vnet-name $VNET   --subnet $SUBNET   --private-connection-resource-id $(az storage account show       --resource-group $RG       --name $STORAGE       --query id -o tsv)   --group-id blob   --connection-name "${PE_NAME}-connection"
```

Then create/link the private DNS zone:

```bash
# Create private DNS zone for blob
az network private-dns zone create   --resource-group $RG   --name privatelink.blob.core.windows.net

# Link it to the VNet
az network private-dns link vnet create   --resource-group $RG   --zone-name privatelink.blob.core.windows.net   --name "vnet-app-link"   --virtual-network $(az network vnet show       --resource-group $RG       --name $VNET       --query id -o tsv)   --registration-enabled false
```

Often, the portal creates these DNS objects for you, but the CLI pattern above is useful to recognize.

---

## 7. Use cases and patterns

### 7.1 Secure Storage account from all public access

Goal: Only allow access to Storage from resources in a specific VNet.

Steps:

1. Create a **private endpoint** for the Storage account in the desired subnet.
2. Configure **private DNS** so clients resolve the Storage endpoint name to the private IP.
3. Set **Public network access = Disabled** on the Storage account.

Result:

- Access is only possible from the VNet(s) that can reach the private endpoint.
- On‑premises networks can also reach it via VPN/ExpressRoute if DNS and routing are configured.

### 7.2 Secure Azure SQL Database

Pattern is similar:

1. Create a private endpoint for the SQL server (`server.database.windows.net`).
2. Use a private DNS zone like `privatelink.database.windows.net`.
3. Optionally disable public access.

Applications in your VNet connect to SQL using the **usual FQDN**, but it resolves to a **private IP**.

### 7.3 Multi-tenant and shared services

You can use private endpoints to:

- Access a **partner’s service** or a **customer’s service** exposed via **Private Link service**.
- Create central PaaS resources (e.g. central Storage/Key Vault) and expose them privately to multiple VNets via private endpoints in each VNet.

---

## 8. Security, NSGs, and limitations

### 8.1 NSGs and private endpoints

- A private endpoint is essentially a NIC, but **you cannot attach an NSG directly to the private endpoint NIC**.
- Instead, you control traffic using NSGs on the **subnet** where the private endpoint is placed.

This means:

- If you deny outbound traffic from the subnet to the private endpoint IP, the resource is not reachable.
- You can restrict which other subnets or VNets can talk to that subnet using routes and NSGs.

### 8.2 Public network access and firewalls

For strongest isolation:

1. Create private endpoints for required services.
2. Set **Public network access = Disabled** (or “Selected networks”) on those services.
3. Configure service-level firewalls to allow only **private endpoint traffic**.
4. Ensure DNS directs clients inside the VNet to the **private IP**, not the public endpoint.

### 8.3 Limitations and considerations

- Each private endpoint is created for a specific **resource and sub-resource** (e.g. Storage `blob` vs `file`). You might need multiple private endpoints for different sub-resources.
- There is a **limit** to the number of private endpoints per VNet/subscription (check Azure limits – not usually tested with exact numbers in AZ‑104).
- Private endpoints are **region‑specific**; typically the VNet and PaaS resource must be in compatible regions.
- You must plan **DNS carefully**, especially in hybrid environments with on‑prem DNS servers.

---

## 9. Private endpoints vs other options (quick decision guide)

When securing access to PaaS resources, you have three main options:

1. **IP Firewall only**
   - Allow specific public IP ranges (e.g. your office IP).
   - Simplest, but traffic still goes over the Internet.

2. **Service endpoints**
   - Restrict to specific VNets/subnets.
   - Traffic goes over Azure backbone, but **endpoint is still public**.
   - Easier to configure, no DNS changes.

3. **Private endpoints (Private Link)**
   - PaaS service reachable via a **private IP** in your VNet.
   - You can disable public access entirely.
   - Requires DNS integration and more configuration.

**AZ‑104 pattern:**

- If the question stresses **“no public internet exposure at all”** or “**must use a private IP inside the VNet**” → **Private endpoint**.
- If the question stresses **“traffic should stay on the Microsoft backbone and be limited to specific subnets”**, but doesn’t require private IPs → **Service endpoint**.

---

## 10. AZ‑104 exam tips

- A **private endpoint** is a **NIC with a private IP** in your VNet connected to a PaaS service via Private Link.
- You usually configure it via:
  - **PaaS resource → Networking → Private endpoint connections**.
  - Or via **az network private-endpoint** commands.
- For correct operation, you need:
  - A **VNet & subnet** for the private endpoint NIC.
  - Proper **DNS resolution** so the service name resolves to the private IP.
- You typically:
  - Create private endpoint.
  - Integrate with **Private DNS zone**.
  - Optionally disable **public network access**.
- Remember:
  - You can’t attach NSGs directly to private endpoint NICs.
  - You control access via **NSGs on the subnet** and via service-level firewalls.
  - Private endpoints allow on-premises clients to reach PaaS via VPN/ExpressRoute, as long as routing and DNS are configured.

Mastering the difference between service endpoints and private endpoints, and knowing **when to use which**, is a core skill for the AZ‑104 networking and security sections.

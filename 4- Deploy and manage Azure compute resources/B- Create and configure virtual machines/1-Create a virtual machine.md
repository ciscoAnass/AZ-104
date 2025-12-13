# Create a Virtual Machine (VM) in Azure

## A. Concept and Exam View

### What is an Azure VM?

An Azure Virtual Machine (VM) is an Infrastructure-as-a-Service (IaaS) compute resource in Azure:

- You get a virtualized server (CPU, RAM, disks, network).
- You control the OS, updates, applications, and configuration.
- Microsoft manages the physical hardware, virtualization layer, and datacenter.

Typical use cases:

- Lift‑and‑shift of on‑prem servers.
- Domain controllers, application servers, jump boxes, legacy workloads.
- Custom software that doesn’t fit PaaS services.

**Exam mindset:**  
You must know:
- The key building blocks of a VM.
- How to create a VM from the portal, CLI, PowerShell, and templates/Bicep (high level).
- Where common configuration options are set (availability, networking, disks, identity, tags).

---

## B. VM Building Blocks

When you create one VM, Azure actually creates several resources.

```text
+---------------------------+
|       Resource Group      |
|  +---------------------+  |
|  |      VM (compute)   |  |
|  |  +---------------+  |  |
|  |  |   OS Disk     |  |  |
|  |  | + Data Disks  |  |  |
|  |  +---------------+  |  |
|  |         | NIC        |
|  +---------|-----------+|
|            v            |
|          Subnet         |
|           |             |
|        VNet             |
|                         |
|  Public IP  +  NSG      |
+-------------------------+
```

Key components:

- **Resource Group (RG)** – Logical container for the VM and its related resources.
- **Region** – Physical location of the datacenter (example: `West Europe`, `East US`).
- **VM (compute resource)** – Defines CPU, RAM, boot diagnostics, identity, etc.
- **OS Disk** – Managed disk that holds the operating system.
- **Data Disks (optional)** – Extra managed disks for application or data.
- **Network Interface (NIC)** – Connects the VM to a virtual network.
- **Virtual Network + Subnet** – Private network where the VM lives.
- **Public IP (optional)** – Internet entry point for RDP/SSH or other services.
- **Network Security Group (NSG)** – Firewall rules for inbound/outbound traffic.
- **Availability option** – None, availability set, or availability zone.
- **Identity and tags** – Managed identity for Azure auth + metadata for cost/ownership.

Exam tip: If a scenario mentions *“only private access from on‑premises”* → no Public IP + VPN/ExpressRoute to the VNet.

---

## C. Planning Before You Create a VM

Before clicking “Create”, think about:

1. **Workload needs**
   - Windows or Linux?
   - Dev/test, production, or lab?
   - How much CPU, RAM, and disk performance?

2. **Region**
   - Close to users for low latency.
   - Required by compliance (country/region).
   - Check that the needed VM size and features exist in that region.

3. **Availability**
   - Single VM (no infra redundancy).
   - **Availability set** for protection vs host failures/maintenance.
   - **Availability zones** for datacenter‑level resiliency.

4. **Authentication**
   - Linux: SSH keys recommended (password discouraged).
   - Windows: strong password + option for Entra (Azure AD) login.
   - Enable just‑in‑time (JIT) VM access where possible (via Defender for Cloud).

5. **Networking & security**
   - VNet & subnet design.
   - NSG rules (don’t open RDP/SSH to everyone).
   - Bastion or VPN for secure access.

6. **Storage**
   - OS disk type (Standard HDD/SSD, Premium SSD, Premium SSD v2, Ultra etc.).
   - Data disks: capacity, IOPS, throughput, redundancy.
   - Backup strategy (Azure Backup).

7. **Governance**
   - Tags (CostCenter, Environment, Owner).
   - Policy/RBAC: can this user create VMs in that subscription/region?

---

## D. Creating a VM in the Azure Portal (Step‑by‑Step)

The portal shows a multi‑tab wizard. The exact UI can change, but the structure is similar.

### 1. Start creation

1. In the Azure portal, search for **“Virtual machines”**.
2. Click **Create** → **Azure virtual machine**.

### 2. Basics tab

Important fields:

- **Subscription** – Which subscription will pay for the VM.
- **Resource group** – Select existing or create new (for related resources).
- **Virtual machine name** – Use a naming convention (for example: `vm-app01-weu`).
- **Region** – Select region (for example `West Europe`).
- **Availability options**
  - No infrastructure redundancy required.
  - Availability zone (1, 2, 3).
  - Availability set.
- **Security type** – Standard or Trusted launch (extra security for Gen2).
- **Image**
  - Marketplace images: Windows Server, Ubuntu, etc.
  - Custom image or Azure Compute Gallery image if provided.
- **Azure Spot instance (optional)**
  - Uses spare capacity at lower cost.
  - VM can be evicted when Azure needs capacity.
  - Good for interruptible workloads only, not for critical servers.
- **Size**
  - Choose VM size (for example: `Standard_B2s`, `Standard_D4s_v5`).
- **Administrator account**
  - Linux: SSH public key or password.
  - Windows: username + strong password.
- **Inbound port rules**
  - Choose which ports to open to the Internet (SSH 22, RDP 3389, HTTP 80, etc.).
  - Best practice: select **None**, and use Bastion/VPN/JIT.

Exam tip: If the question mentions “Spot VM may be evicted, but should be deleted automatically” → configure the eviction policy to **Delete**, not **Deallocate**.

### 3. Disks tab

You normally select:

- **OS disk type** – Standard HDD, Standard SSD, Premium SSD, Premium SSD v2, etc.
- **OS disk size** – Default can be changed for some images.
- **Use ephemeral OS disk** (optional)
  - OS stored on local node storage; super fast but non‑persistent.
  - Ideal for stateless workloads; no backup of OS disk.

You can also:

- Add data disks.
- Choose managed disk type for each data disk.

### 4. Networking tab

Key elements:

- **Virtual network** – Choose existing or create new.
- **Subnet** – The specific subnet in the VNet.
- **Public IP** – None (private only) or new/existing PIP.
- **NIC network security group**
  - Basic: you select inbound ports and Azure creates NSG rules.
  - Advanced: link to existing NSG or skip and configure later.
- **Load balancing** (optional)
  - Put the VM behind an Azure Load Balancer or Application Gateway.

Exam pattern: If a requirement says *“VM must not be directly exposed to Internet, but admins need RDP access”* → No public IP + Azure Bastion or VPN + NSG allowing RDP from Bastion subnet/VPN.

### 5. Management tab

Common options:

- **Azure Monitor / Boot diagnostics**
  - Enable diagnostics to a storage account or managed storage.
- **Identity**
  - System‑assigned managed identity: VM gets an identity in Entra ID.
  - Used to access Key Vault, storage, etc., without embedded secrets.
- **Backup**
  - Enable Azure Backup and choose backup policy.
- **Auto‑shutdown**
  - Useful for dev/test; schedule daily shutdown.
- **Patch orchestration options** – For Windows/Linux patching behavior.

### 6. Monitoring, Advanced, Tags

- **Monitoring tab**
  - Enable guest‑level monitoring, metrics, and logs.
- **Advanced tab**
  - Cloud‑init script for Linux.
  - VM extensions (Custom Script Extension, Log Analytics agent, etc.).
- **Tags tab**
  - Add `Environment=Prod`, `CostCenter=HR`, etc., for governance and billing.

### 7. Review + Create

- Azure validates settings.
- Click **Create** to start deployment.
- Deployment creates:
  - VM.
  - NIC, NSG, public IP (if selected).
  - Disks.
  - Any load balancer or diagnostic resources you configured.

---

## E. Creating a VM Using Azure CLI

You can create a VM with a single `az vm create` command.

### Example: Create a Linux VM

```bash
# 1. Create resource group
az group create \
  --name rg-az104-compute \
  --location westeurope

# 2. Create a VM
az vm create \
  --resource-group rg-az104-compute \
  --name vm-linux-web01 \
  --image Ubuntu2204 \
  --size Standard_B2s \
  --admin-username azureuser \
  --generate-ssh-keys \
  --public-ip-sku Standard
```

What this does:

- Creates the VM and default supporting resources:
  - VNet, subnet, NSG, NIC, public IP.
- Uses generated SSH keys for secure login.
- Uses standard public IP and opens SSH (22) by default unless changed.

### Example: Create a Windows VM

```bash
az vm create \
  --resource-group rg-az104-compute \
  --name vm-win-app01 \
  --image "WindowsServer2022-Datacenter" \
  --size Standard_D2s_v5 \
  --admin-username azureadmin \
  --admin-password "P@ssw0rd-ChangeMe-123!" \
  --public-ip-sku Standard
```

You’ll RDP to this VM using the public IP and port 3389 (unless NSG says otherwise).

Exam tip: Remember that `az vm create` can auto‑create network resources, but in production you typically pre‑create VNet, subnet, NSG, etc., then attach the VM to them.

---

## F. Creating a VM Using PowerShell (High Level)

Basic pattern:

```powershell
# Connect and select subscription
Connect-AzAccount
Select-AzSubscription -Subscription "MySubName"

# Create resource group
New-AzResourceGroup -Name "rg-az104-compute" -Location "westeurope"

# Create VM (simplified)
New-AzVm -Name "vm-win-ps01" `
  -ResourceGroupName "rg-az104-compute" `
  -Location "westeurope" `
  -VirtualNetworkName "vnet-az104" `
  -SubnetName "subnet-app" `
  -SecurityGroupName "nsg-az104" `
  -PublicIpAddressName "pip-vm-win-ps01" `
  -OpenPorts 3389
```

You usually pass a `PSCredential` object for the admin account, and you can customize disk and size settings using additional parameters.

---

## G. Connect to the VM

### Linux – SSH

From Linux/macOS or Windows Terminal (with OpenSSH):

```bash
ssh azureuser@<public-ip-address>
```

If your key is not the default one, specify it with `-i`:

```bash
ssh -i ~/.ssh/mykey azureuser@<public-ip-address>
```

### Windows – RDP

1. On your local machine, open **Remote Desktop Connection** (`mstsc`).
2. Enter the VM’s public IP and connect with the admin username/password.
3. Ensure NSG allows inbound port 3389 from your IP.

### Bastion (secure option)

- Azure Bastion lets you open RDP/SSH directly in the browser over TLS.
- No public IP needed on the VM.
- You connect from the portal → Bastion → VM.

Exam tip: If a requirement says *“do not expose RDP/SSH to the Internet”* and *“admins must connect from the Azure portal”* → correct answer usually includes **Azure Bastion**.

---

## H. Using Images and Azure Compute Gallery

You can create VMs from:

- **Marketplace images** – Provided by Microsoft or partners (Windows Server, Ubuntu, SQL Server, etc.).
- **Custom images** – An image you captured from a “golden” VM (sysprepped/deprovisioned).
- **Azure Compute Gallery** – Central place to store and version images, replicate them to multiple regions, and use them at scale.

Common path:

1. Build a golden VM, configure OS, install software.
2. Generalize (sysprep for Windows, `waagent -deprovision+user` for Linux).
3. Capture image → store in Azure Compute Gallery.
4. Create new VMs from that image across regions/subscriptions.

Exam tip: If you see *“standardize OS and preinstalled software for many VMs across regions”* → think **Azure Compute Gallery**.

---

## I. Best Practices & Exam Tips

**Security**

- Prefer SSH keys for Linux instead of passwords.
- Don’t open SSH/RDP to “Any” (`0.0.0.0/0`). Lock it down to specific IPs or use Bastion.
- Enable boot diagnostics and monitoring to troubleshoot startup issues.

**Availability**

- For production workloads, don’t run a single VM if you need high availability.
- Use **availability sets** or **availability zones**, plus load balancing.

**Governance and cost**

- Use tags consistently for cost and management.
- For dev/test, enable auto‑shutdown and consider Spot VMs.
- Use Azure Policy definitions to enforce allowed locations, VM sizes, and tag rules.

**Automation**

- For repeatable deployments, use ARM templates or Bicep, not only the portal.
- Combine templates with parameter files for different environments (dev/test/prod).

---

## J. Quick Summary for the Exam

- A VM is built from compute, disks, NIC, VNet, NSG, and optional public IP.
- You can create VMs via Portal, CLI (`az vm create`), PowerShell (`New-AzVm`), ARM templates, and Bicep.
- Availability, storage, networking, and identity are all chosen during creation.
- Secure RDP/SSH access and follow least‑privilege + least exposure principles.
- For repeatable, compliant deployments → use templates/Bicep + Policy.

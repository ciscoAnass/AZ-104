# Configure Public IP Addresses

> AZ-104 Objective: **Configure public IP addresses**

---

## 1. What is a Public IP Address in Azure?

A **Public IP address (PIP)** in Azure is used to allow:

- Inbound connections **from the internet** to Azure resources.
- Outbound connections **from your resources to the internet**, where services on the internet see the PIP as the source.

Common associations:

- Virtual machine NICs
- Load balancer frontends (Standard or Basic)
- Application Gateway
- VPN gateways, Bastion, NAT gateways, etc.

**Important:** PIPs are Azure resources that you create and then associate with other resources.

---

## 2. Key Properties of Public IPs

When you create a Public IP, you must understand these options:

1. **SKU**: Basic vs Standard  
2. **Assignment**: Dynamic vs Static  
3. **IP Version**: IPv4 and/or IPv6  
4. **Tier**: Regional vs Global (for some services)  
5. **DNS label**: Optional name like `myvm.eastus.cloudapp.azure.com`

### 2.1 SKU: Basic vs Standard

| Feature                    | Basic                                | Standard                                             |
|---------------------------|--------------------------------------|------------------------------------------------------|
| Availability              | Older, legacy                        | Recommended for production                           |
| Security                  | Open by default                      | **Secure by default** (no inbound until configured)  |
| Supported with zone-Redundancy | Limited                         | Yes (zone-redundant or zonal)                        |
| Load balancer support     | Basic Load Balancer                  | Standard Load Balancer                               |
| IP assignment             | Dynamic (default) / Static           | Static only                                          |

**Exam-level idea:**  
For production workloads and newer designs, **Standard** SKU is the expected choice.

### 2.2 IP Allocation: Static vs Dynamic

- **Static**: IP is reserved to the resource until you release it.
  - Good for DNS records, firewall rules.
- **Dynamic**: IP is allocated when the resource is started or created and may change when released.
  - For Standard PIP, allocation is effectively static; for Basic, dynamic is common.

**Exam tip:**  
> If question mentions that a public IP must remain the same over time and be added to DNS or firewall rules → choose **Static**.

### 2.3 IP Version: IPv4 and IPv6

- Most typical usage: **IPv4**.
- You can create **IPv6** PIPs for dual-stack applications.
- Load balancers can have both IPv4 and IPv6 frontends.

### 2.4 DNS Label

Optional **DNS name label** gives your IP a hostname like:

```text
myvm.eastus.cloudapp.azure.com
```

- Useful for accessing resources without remembering raw IP addresses.
- The DNS label must be unique within the Azure region.

---

## 3. Creating a Public IP (Portal)

### 3.1 Steps

1. Go to **Azure portal** → **Create a resource** → search **Public IP address**.
2. Click **Create**.
3. **Basics:**
   - Subscription, Resource group: e.g., `rg-network-weu`.
   - Name: `pip-web-01`.
   - Region: e.g., `West Europe`.
4. **IP Version:** IPv4 (default) or IPv6.
5. **SKU:** Standard (recommended) or Basic.
6. **IP address assignment:** Static or Dynamic (depending on SKU).
7. **Tier:** Regional (default) or Global (for certain services like Azure Front Door or specific scenarios).
8. **DNS name label (optional):** e.g., `hospital-web-01` → `hospital-web-01.westeurope.cloudapp.azure.com`.
9. **Review + create** → **Create**.

### 3.2 Associate a Public IP with a VM NIC (Portal)

1. Go to your **Virtual Machine**.
2. Click **Networking**.
3. Under **Network interface**, select the NIC.
4. Click **IP configurations**.
5. Select the **primary IP configuration** (e.g., `ipconfig1`).
6. Under Public IP address:
   - Click **Associate** → choose existing Public IP or create new.
7. Save.

After a few seconds, the VM has internet-reachable IP.

---

## 4. Creating and Managing Public IPs with Azure CLI

### 4.1 Create a Static Standard Public IP

```bash
az network public-ip create \
  --resource-group rg-network-weu \
  --name pip-web-01 \
  --sku Standard \
  --allocation-method Static \
  --version IPv4
```

### 4.2 Create a Basic Dynamic Public IP with DNS Label

```bash
az network public-ip create \
  --resource-group rg-network-weu \
  --name pip-test-01 \
  --sku Basic \
  --allocation-method Dynamic \
  --dns-name hospital-test-web \
  --version IPv4
```

### 4.3 Associate PIP with a VM’s NIC

Assume:

- VM: `vm-web-01`
- NIC: `nic-web-01`
- Public IP: `pip-web-01`

```bash
# Associate public IP with NIC
az network nic ip-config update \
  --resource-group rg-network-weu \
  --nic-name nic-web-01 \
  --name ipconfig1 \
  --public-ip-address pip-web-01
```

### 4.4 List Public IPs

```bash
az network public-ip list \
  --resource-group rg-network-weu \
  --output table
```

### 4.5 Show Details of a Public IP

```bash
az network public-ip show \
  --resource-group rg-network-weu \
  --name pip-web-01 \
  --output json
```

---

## 5. Public IPs with Load Balancers and Other Services

### 5.1 Load Balancer Frontend IP Configuration

For an internet-facing load balancer, you associate a **public IP** with the frontend:

```bash
az network public-ip create \
  --resource-group rg-lb-weu \
  --name pip-lb-01 \
  --sku Standard \
  --allocation-method Static

az network lb create \
  --resource-group rg-lb-weu \
  --name lb-web-01 \
  --sku Standard \
  --frontend-ip-name fe-web \
  --backend-pool-name be-web \
  --public-ip-address pip-lb-01
```

- Clients on the internet connect to the **public IP**.
- Load balancer distributes traffic to backend pool VMs using **private IPs**.

### 5.2 Application Gateway, VPN Gateway, Bastion, NAT Gateway

Many Azure services require or can use a PIP:

- **Application Gateway**: for internet-facing web applications.
- **VPN Gateway**: to terminate VPN tunnels from on‑prem.
- **Azure Bastion**: provides secure browser-based RDP/SSH into VMs.
- **NAT Gateway**: provides outbound-only internet for subnets.

In all these, you typically create a PIP and attach it during service creation.

---

## 6. Outbound Connectivity and Public IPs

### 6.1 Direct Public IP on VM

If a VM has a PIP on its NIC:

- Outbound connections use its PIP as **source IP**.
- Inbound connections can come from internet (if NSG allows).

### 6.2 SNAT via Load Balancer or NAT Gateway

Even if VMs do not have individual PIPs, they can go out to the internet via:

- **Load balancer outbound rules**
- **NAT Gateway**

In these cases, a shared Public IP (or pool of IPs) is used.

**Exam tip:**  
> For scalable, controlled outbound access, **NAT Gateway** is preferred over giving each VM its own PIP.

---

## 7. Security Considerations for Public IPs

Public IPs = exposed endpoints. Combine them with security controls:

1. **Network Security Groups (NSGs):**
   - Restrict inbound ports (e.g., allow 443, block 3389 from internet).
2. **Azure Firewall / NVA:**
   - Place PIP on firewall and route traffic through it.
3. **Just-in-Time (JIT) VM access:**
   - Temporarily open management ports like RDP/SSH.
4. **Avoid direct RDP/SSH from internet:**
   - Prefer **Azure Bastion** or VPN.

**Best practice:**  
Give public IPs only to **entry points** (load balancers, gateways, Bastion), not to all VMs.

---

## 8. Example Architecture: Secure Web App

```text
Internet
   │
Public IP
   │
Azure Application Gateway (WAF)
   │
VNet (10.10.0.0/16)
   └── Subnet: snet-web (10.10.1.0/24)
        └── VMs (no direct PIPs)
```

- Public IP attached only to **App Gateway**.
- Web VMs have **private IPs** only and live behind NSGs and WAF.
- Outbound internet for VMs might go through NAT Gateway or firewall.

---

## 9. Common Questions and Scenarios

### Q1: Static vs Dynamic PIP for a Web Server?

You want to publish a public website from a single VM and create an A record in your custom DNS pointing to the IP. Which allocation method?

- **Answer:** **Static**. You cannot risk the IP changing.

### Q2: Need to Restrict Who Can Reach the PIP

Your VM has a public IP, but you must allow only admins from your office public IP to access it via SSH.

- Configure an NSG rule:
  - Source IP = your office IP range.
  - Destination = VM, port 22 (SSH).
  - Deny everything else.

### Q3: Public IP Must Not Be Reachable from Internet

You want a VM to have a PIP only for outbound connectivity (not accept inbound). What options?

- Use **NAT Gateway** for outbound only (preferred).
- Or apply **NSG rules** that deny all inbound from internet, but allow outbound.

---

## 10. Exam Tips and Traps

1. **Standard PIP = secure by default**  
   - No inbound allowed until also configured with NSG and load balancer/listener.
2. **Static IP = required for stable DNS and firewall rules**.
3. **Basic vs Standard** questions often hide in choice of load balancer.
4. Remember PIPs are also used with **VPN Gateways**, **Application Gateway**, **Bastion**, **NAT Gateway**.
5. Public IP + NSG misconfiguration is a common exam scenario:
   - They may show you a VM with a PIP that is still not reachable; reason is NSG or missing LB rules.

---

If you understand all these aspects of public IP addresses, you will be ready for AZ‑104 questions that ask you to design or troubleshoot public-facing connectivity in Azure.

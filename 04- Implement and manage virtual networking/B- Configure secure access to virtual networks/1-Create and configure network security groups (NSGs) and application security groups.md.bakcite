# Create and configure network security groups (NSGs) and application security groups (ASGs)

_AZ-104 exam objective: Configure secure access to virtual networks using NSGs and ASGs._

---

## 1. Big picture: why NSGs and ASGs?

Imagine you manage a hospital system in Azure:

- Web servers in a **front-end subnet**
- App servers in a **middle-tier subnet**
- Databases in a **data subnet**

You want:

- Internet users → only reach the web servers on HTTPS (443)
- Web servers → talk to app servers
- App servers → talk to database servers
- Nothing else allowed

In Azure, you implement this network security with:

- **Network Security Groups (NSGs)** → the actual firewall rules
- **Application Security Groups (ASGs)** → labels you attach to NICs, so you don’t have to manage IP addresses

For AZ‑104, you must know **what NSGs/ASGs are, how to create them, how to associate them, and how they interact.**

---

## 2. Network Security Groups (NSGs)

### 2.1 What is an NSG?

An **NSG** is a stateful, layer 3/4 firewall for Azure resources.

- It contains **security rules** that **allow or deny** traffic.
- You can apply NSGs to:
  - **Subnets** (affects all NICs in that subnet)
  - **Network interfaces (NICs)** (affects only that NIC/VM)
- NSGs filter **inbound** and **outbound** traffic.

> **Stateful** = if inbound traffic is allowed, return traffic is automatically allowed. You don’t need separate outbound rules for the reply, and vice versa.

Typical use cases:

- Allow RDP/SSH only from an admin subnet
- Allow HTTP/HTTPS from Internet to a web subnet
- Block all traffic except specific application ports

---

### 2.2 NSG security rule structure

Each NSG rule has these key fields:

| Field        | Description |
|-------------|-------------|
| **Name**    | Friendly name for the rule (e.g. `Allow-HTTPS-Internet`) |
| **Priority**| Integer **100–4096**. Lower number = higher priority. First match wins. |
| **Direction** | `Inbound` or `Outbound` (relative to the NIC) |
| **Protocol**| `Any`, `TCP`, `UDP`, `ICMP`, etc. |
| **Source**  | Where traffic comes from: IP range, **service tag**, or **ASG** |
| **Source port(s)** | Usually `*` (any). Can be specific ports (rare). |
| **Destination** | IP range, service tag, or ASG |
| **Destination port(s)** | Port or range (e.g. `80`, `443`, `3389`, `1000-2000`, `*`) |
| **Action**  | `Allow` or `Deny` |

#### Rule evaluation logic (very important for exam)

For a given packet:

1. Azure looks at **all rules for that direction** (inbound or outbound).
2. It sorts them by **priority (smallest number first)**.
3. It finds the **first rule where all fields match** (source, destination, protocol, ports).
4. It applies that rule’s **Allow/Deny** and **stops**. Lower-priority rules are ignored.

> If **no user rule matches**, a **default rule** (with high priority number) decides.

---

### 2.3 Default NSG rules

Every NSG includes built‑in rules you **cannot delete**, only override with higher priority (lower number) rules.

| Direction | Priority | Name                       | Source       | Destination  | Port    | Action |
|----------|----------|----------------------------|--------------|--------------|---------|--------|
| Inbound  | 65000    | AllowVNetInBound           | VirtualNetwork | VirtualNetwork | *   | Allow |
| Inbound  | 65001    | AllowAzureLoadBalancerInBound | AzureLoadBalancer | * | * | Allow |
| Inbound  | 65500    | DenyAllInBound             | *            | *            | *       | Deny  |
| Outbound | 65000    | AllowVNetOutBound          | VirtualNetwork | VirtualNetwork | *   | Allow |
| Outbound | 65001    | AllowInternetOutBound      | *            | Internet     | *       | Allow |
| Outbound | 65500    | DenyAllOutBound            | *            | *            | *       | Deny  |

**Key ideas:**

- By default, **resources in the same VNet can talk to each other** (AllowVNet rules).
- By default, **outbound to Internet is allowed**.
- By default, **inbound from Internet is denied** (unless you create rules to allow).

**Exam pattern:**

If they show you rules with priority 100, 200, and then ask which one applies, always pick the **first matching rule with the lowest number**.

---

### 2.4 Where can you associate NSGs?

You can link NSGs to:

1. **Subnets** in a virtual network
2. **Network interfaces (NICs)** of VMs

Rules from both levels are combined:

- For traffic to be **allowed**, it must be allowed by **both**:
  - NSG on the **subnet**, and
  - NSG on the **NIC**

Think of it like this:

```text
Inbound packet
   └─> Subnet NSG ──(must Allow)──> NIC NSG ──(must Allow)──> VM
```

If **either** NSG has a **Deny** that matches first, the traffic is blocked.

**Design guidance:**

- Use **subnet NSGs** for **baseline** rules (e.g. only web ports into web subnet).
- Use **NIC NSGs** for **exceptions**, if you really need them.
- For simplicity, many real-world designs use **only subnet NSGs**.

> AZ‑104 tip: You do **not** associate NSGs with VNets directly, only with subnets or NICs.

---

### 2.5 Service tags in NSG rules

**Service tags** are special labels that represent groups of IP addresses for Azure services.

Common examples:

- `VirtualNetwork` – all IPs in the VNet (and peered VNets, depending on context)
- `Internet` – traffic to/from public Internet
- `AzureLoadBalancer` – the IPs of Azure’s internal load balancer probes
- `AzureCloud`, `Storage`, `Sql`, `KeyVault`, etc. – specific Azure services

Use service tags instead of typing huge IP ranges.

**Example:** Allow HTTP from the Internet to a web subnet.

- Source: `Internet`
- Destination: `VirtualNetwork`
- Destination port: `80`
- Action: Allow

---

### 2.6 Creating an NSG in the Azure portal

**Scenario:** Create an NSG for a web subnet that allows HTTP/HTTPS from the Internet and denies everything else inbound.

#### Step 1 – Create the NSG

1. Go to **Azure portal** → search for **Network security groups**.
2. Click **Create**.
3. Choose:
   - **Subscription**
   - **Resource group** (or create new)
   - **Name**: `nsg-web-subnet`
   - **Region**: same region as the VNet/subnet.
4. Click **Review + create** → **Create**.

#### Step 2 – Create inbound rules

Inside `nsg-web-subnet` → **Inbound security rules** → **Add**:

1. **Allow-HTTP-from-Internet**
   - Priority: `100`
   - Source: `ServiceTag` → `Internet`
   - Source port: `*`
   - Destination: `Any` (or `VirtualNetwork`)
   - Destination port: `80`
   - Protocol: `TCP`
   - Action: `Allow`

2. **Allow-HTTPS-from-Internet**
   - Priority: `110`
   - Source: `Internet`
   - Destination: `Any` (or `VirtualNetwork`)
   - Destination port: `443`
   - Protocol: `TCP`
   - Action: `Allow`

3. (Optional, but good practice) **Deny-all-other-inbound**
   - Priority: `120`
   - Source: `Any`
   - Destination: `Any`
   - Destination port: `*`
   - Protocol: `Any`
   - Action: `Deny`

This explicit Deny will match before the default `DenyAllInBound` at priority 65500, and makes intent clear.

#### Step 3 – Associate the NSG to a subnet

1. Still in `nsg-web-subnet`, go to **Subnets** → **Associate**.
2. Choose:
   - Virtual network: e.g. `vnet-hospital`
   - Subnet: e.g. `snet-web`
3. Click **OK**.

Now **all NICs** in `snet-web` are protected by this NSG.

---

### 2.7 Creating NSGs and rules with Azure CLI

You should recognize basic CLI syntax for the exam.

#### Create an NSG

```bash
# Create NSG
az network nsg create   --resource-group rg-hospital   --name nsg-web-subnet   --location westeurope
```

#### Add an inbound allow rule for HTTPS from Internet

```bash
az network nsg rule create   --resource-group rg-hospital   --nsg-name nsg-web-subnet   --name Allow-HTTPS-From-Internet   --priority 100   --access Allow   --direction Inbound   --protocol Tcp   --source-address-prefixes Internet   --source-port-ranges '*'   --destination-address-prefixes '*'   --destination-port-ranges 443
```

#### Associate NSG with a subnet

```bash
az network vnet subnet update   --resource-group rg-hospital   --vnet-name vnet-hospital   --name snet-web   --network-security-group nsg-web-subnet
```

#### Associate NSG with a NIC

```bash
# Example NIC name attached to a VM
az network nic update   --resource-group rg-hospital   --name vmweb01-nic   --network-security-group nsg-web-subnet
```

On the exam, you mainly need to **recognize** commands like `az network nsg create` and `az network nsg rule create` and understand what they do.

---

## 3. Application Security Groups (ASGs)

### 3.1 Why ASGs?

Without ASGs you end up with NSG rules like:

- Source: `10.0.1.4, 10.0.1.5, 10.0.1.6` (web servers)
- Destination: `10.0.2.4, 10.0.2.5` (app servers)

As servers scale or their IPs change, you must constantly update NSG rules. That doesn’t scale.

**Application Security Groups (ASGs)** solve this by letting you:

- Group NICs by **application role**, not by IP.
- Use ASG names in NSG rules as **source/destination**.
- Let Azure handle the mapping of ASGs to IPs.

> Think of ASGs as **dynamic tags** you attach to NICs.

---

### 3.2 ASG characteristics

- ASGs are **regional** and **subscription‑scoped**.
  - You can use an ASG across multiple VNets in **the same region + subscription**.
- ASGs contain **network interfaces**, not subnets.
- A NIC can be in **multiple ASGs** (e.g. `asg-web`, `asg-linux`).

You **never** assign an NSG to an ASG. Instead:

- You **create NSG rules** that **reference ASGs** as source/destination.

---

### 3.3 Creating an ASG in the Azure portal

**Step 1 – Create ASG**

1. In the portal, search for **Application security groups**.
2. Click **Create**.
3. Settings:
   - Resource group: `rg-hospital`
   - Name: `asg-web`
   - Region: `West Europe` (must match NIC region)
4. Click **Review + create** → **Create**.

Repeat for `asg-app`, `asg-db`, etc.

**Step 2 – Add NICs (VMs) to ASGs**

1. Go to **Virtual machines** → `vmweb01` → **Networking**.
2. Under **Network interface**, click the NIC name (e.g. `vmweb01-nic`).
3. In the NIC blade, go to **Application security groups**.
4. Click **+ Associate**, then select `asg-web`.
5. Save.

Now `vmweb01` is part of `asg-web`. Repeat for all web VMs, app VMs, DB VMs, etc.

---

### 3.4 Using ASGs in NSG rules (3‑tier example)

We have ASGs:

- `asg-web` – all web servers
- `asg-app` – all application servers
- `asg-db` – all database servers

And one NSG on the app subnet: `nsg-app-subnet`.

We want:

1. Allow HTTP/HTTPS from `asg-web` → `asg-app`.
2. Allow SQL traffic from `asg-app` → `asg-db`.
3. Deny everything else.

**Rule 1 – Web to App on HTTP/HTTPS**

- NSG: `nsg-app-subnet` (associated with app subnet)
- Direction: Inbound
- Priority: `100`
- Source: **ASG** → `asg-web`
- Source port: `*`
- Destination: **ASG** → `asg-app`
- Destination ports: `80,443`
- Protocol: `TCP`
- Action: `Allow`

**Rule 2 – App to DB on SQL (port 1433)**

Can be defined on NSG on DB subnet, inbound:

- NSG: `nsg-db-subnet`
- Direction: Inbound
- Priority: `100`
- Source: ASG → `asg-app`
- Destination: ASG → `asg-db`
- Destination port: `1433`
- Protocol: `TCP`
- Action: `Allow`

**Rule 3 – Deny all other inbound**

- Priority: `200`
- Source: `Any`
- Destination: `Any`
- Port: `*`
- Action: `Deny`

This way, instead of managing IP addresses, you manage **groups of NICs**.

---

### 3.5 Creating ASGs and using them in rules with Azure CLI

#### Create ASGs

```bash
# Web ASG
az network asg create   --resource-group rg-hospital   --name asg-web   --location westeurope

# App ASG
az network asg create   --resource-group rg-hospital   --name asg-app   --location westeurope
```

#### Attach NIC to an ASG

```bash
az network nic update   --resource-group rg-hospital   --name vmweb01-nic   --application-security-groups asg-web
```

> If you want to attach multiple ASGs, provide a space‑separated list after `--application-security-groups`.

#### Use ASG in an NSG rule

```bash
az network nsg rule create   --resource-group rg-hospital   --nsg-name nsg-app-subnet   --name Allow-Web-To-App   --priority 100   --access Allow   --direction Inbound   --protocol Tcp   --source-asgs asg-web   --destination-asgs asg-app   --destination-port-ranges 80 443   --source-port-ranges '*'
```

---

## 4. NSGs + ASGs design patterns and best practices

### 4.1 Typical design pattern

```text
VNet: vnet-hospital
  ├─ Subnet: snet-web   ── NSG: nsg-web-subnet
  │     └─ VMs: vmweb01, vmweb02  ── ASG: asg-web
  ├─ Subnet: snet-app   ── NSG: nsg-app-subnet
  │     └─ VMs: vmapp01, vmapp02  ── ASG: asg-app
  └─ Subnet: snet-db    ── NSG: nsg-db-subnet
        └─ VMs: vmdb01, vmdb02    ── ASG: asg-db
```

- **Subnet NSGs** define **which tiers can talk** to which tiers.
- **ASGs** define **which VMs are in each tier**.

This gives you **micro-segmentation** without tracking IPs.

---

### 4.2 Best practices

- **Prefer subnet NSGs** for broad policies, NIC NSGs only for specific edge cases.
- Use **ASGs** to avoid using IP addresses in NSG rules.
- Use **service tags** for Azure services or Internet access, rather than IP ranges.
- Keep rule sets **simple and explicit**:
  - Put **specific Allow** rules with lower priority numbers.
  - Add a **catch‑all Deny** only if needed (default Deny already exists).
- Name rules clearly: include direction, port, and purpose (e.g. `Allow-HTTPS-Internet-Inbound`).
- Enable **NSG flow logs** and **Azure Monitor** for troubleshooting and auditing.
- Remember NSGs are **stateful**: only create rules for the **initiating** direction.

---

### 4.3 AZ‑104 exam tips

- NSG = **allow/deny rules** at subnet or NIC level.
- ASG = **group of NICs** used inside NSG rules (never holds rules by itself).
- Lower priority number = **higher priority**.
- First matching rule wins, processing stops.
- If subnet NSG allows but NIC NSG denies (or vice versa), **traffic is denied**.
- Default rules allow VNet‑to‑VNet communication and outbound Internet, but **deny inbound**.
- You cannot associate an NSG directly with:
  - A VNet (only subnets)
  - A VM (only NICs, but that effectively controls the VM)
- Use ASGs + NSGs for **3‑tier application** scenarios that appear often in questions.

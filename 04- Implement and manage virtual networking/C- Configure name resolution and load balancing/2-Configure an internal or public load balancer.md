# Configure an internal or public load balancer

## A. Azure Load Balancer overview

**Azure Load Balancer** is a **Layer 4 (TCP/UDP)** load balancer. It distributes traffic based on IP address and port, not on HTTP path or cookies. citeturn0search1turn0search4turn2search16

It is used to:

- Spread inbound traffic across multiple VMs / VM scale set instances.
- Provide **high availability** within a region or across regions.
- Provide **outbound internet connectivity** (SNAT) for private workloads (Standard SKU).
- Load‑balance both **public** and **internal** traffic.

There are three SKUs: **Basic**, **Standard**, and **Gateway**. Basic is being retired (Sep 30, 2025) and should not be used for new deployments. Standard is the main SKU for AZ‑104. citeturn2search0turn2search4turn2search8turn2search26

### Public vs Internal Load Balancer

- **Public Load Balancer**
  - Has a **public frontend IP**.
  - Accepts traffic from the **internet**.
  - Typical use: public web apps, RDP/SSH via NAT rules, VPN gateways, Azure Virtual Desktop gateways.

- **Internal Load Balancer (ILB)**
  - Has a **private frontend IP** in a subnet.
  - Accessible **only** from inside the VNet, peered VNets, or over VPN/ExpressRoute.
  - Typical use: internal business apps, SQL Always On, middle tiers.

**Visual comparison:**

```text
Internet
   │
[ Public LB ]  (frontend: public IP)
   │
backend pool (VM1, VM2 in subnet)

VNet
 └─ Subnet
     └─ [ Internal LB ] (frontend: 10.0.0.10)
           │
           └─ backend pool (App01, App02)
```

---

## B. Core components of Azure Load Balancer

Azure Load Balancer is configured from a few key building blocks. citeturn0search20turn0search7turn0search18turn2search11

### 1. Frontend IP configuration

- The IP address clients connect to.
- Can be:
  - **Public IP** → creates a **public load balancer**.
  - **Private IP** in a subnet → creates an **internal load balancer**.
- A single load balancer can have **multiple frontends** (multi‑VIP). citeturn0search18turn0search20

### 2. Backend pool

- The **targets** that receive traffic.
- Backend members can be:
  - Virtual machine NICs.
  - VM scale set instances.
  - IP addresses (Standard SKU). citeturn2search0turn2search16

The load balancer distributes flows among healthy backend instances.

### 3. Health probes

- **Probes** regularly check if backend instances are healthy. citeturn2search11turn2search7
- Types:
  - **TCP probe** – checks whether a TCP port is open.
  - **HTTP / HTTPS probe** – sends an HTTP GET to a path (e.g. `/health`) and expects a 200 response.
- Probe settings include:
  - Protocol, port, path (for HTTP/S).
  - Interval and number of failed attempts before marking instance **unhealthy**.

For Standard Load Balancer to probe correctly you must allow probe traffic (source IP `168.63.129.16` or service tag **AzureLoadBalancer**) through NSGs and local firewalls. citeturn2search7turn2search11

### 4. Load‑balancing rules

- Defines how traffic from a frontend is distributed to the backend pool.
- Key properties:
  - Frontend IP and port (e.g. 80).
  - Backend port (e.g. 80 or different).
  - Protocol (TCP or UDP).
  - Session persistence (None / Client IP / Client IP and protocol).
  - Idle timeout, TCP reset on idle (Standard SKU). citeturn0search1turn2search0turn2search11

**HA Ports** (Standard internal LB only): one special rule that load‑balances **all ports** for a given frontend IP — used for scenarios like NVA appliances and firewalls. citeturn2search20turn2search26

### 5. Inbound NAT rules

- Map a **single frontend port** to a specific backend VM and port.
- Often used to provide **RDP / SSH** access to each VM in the pool.
  - Example: Frontend port 50001 → VM1:3389, 50002 → VM2:3389.

### 6. Outbound rules (Standard SKU)

- Control **SNAT** (Source Network Address Translation) for outbound internet traffic from backend instances.
- Define which frontend IP(s) and ports are used for outbound flows.
- Help avoid **SNAT port exhaustion** by scaling out IPs or using Azure NAT Gateway. citeturn0search5turn2search0turn2search2

---

## C. Standard vs Basic Load Balancer (exam‑level view)

While Basic is being retired, exam questions may still reference it. Key differences: citeturn2search0turn2search4turn2search8turn2search26

| Feature | Standard | Basic |
|--------|----------|-------|
| Availability | **SLA** and zone‑aware | No SLA, no zone support |
| Security | **Secure by default** – closed to inbound unless NSG allows | Open by default (NSG optional) |
| Scale | High scale, recommended for production | Small scale, dev/test only |
| Backend | IP or NIC | NIC only |
| Outbound rules | **Supported** | Not supported |
| HA ports | **Supported** | Not supported |
| Multi‑frontend | Inbound + outbound | Inbound only |
| Retirement | Active | Retiring Sep 30, 2025 |

**Exam rule of thumb:** Always choose **Standard** for new production workloads.

---

## D. Configure a public load balancer (portal walk‑through)

Scenario: You want a public load balancer distributing HTTP traffic to two web VMs in an availability set or VM scale set.

### 1. Prerequisites

- A **virtual network** and subnet.
- Two or more VMs (Web01, Web02) with:
  - Web server listening on port 80.
  - NSG that allows HTTP from the load balancer and internet if required.

### 2. Create a public IP address

1. Portal → **Create a resource** → **Public IP address**.
2. SKU: **Standard**.
3. Assignment: **Static** (recommended for predictable DNS mapping).
4. Name: `pip-web-lb`.

### 3. Create the load balancer

1. Portal → **Create a resource** → **Load Balancer**.
2. Type: **Public**.
3. SKU: **Standard**.
4. Tier: Regional (for normal use; choose Global only when needed).
5. Frontend IP configuration: select `pip-web-lb`.
6. Choose resource group, region → Create.

### 4. Configure backend pool

1. Open the load balancer → **Backend pools** → **Add**.
2. Name: `be-web`.
3. Backend pool configuration: choose NIC/VM or VM scale set.
4. Add Web01 and Web02 NICs.
5. Save.

### 5. Configure a health probe

1. In the load balancer → **Health probes** → **Add**.
2. Name: `hp-http`.
3. Protocol: HTTP.
4. Port: 80.
5. Path: `/` or better a dedicated `/health` endpoint if your app has one.
6. Interval & unhealthy threshold: leave defaults, or fine‑tune.

Ensure NSGs and local firewalls allow the probe source (`AzureLoadBalancer` tag / 168.63.129.16). citeturn2search7turn2search11

### 6. Create a load‑balancing rule

1. Go to **Load‑balancing rules** → **Add**.
2. Name: `lbr-http`.
3. Frontend IP: select the public IP frontend.
4. Protocol: TCP.
5. Port: 80 (frontend).
6. Backend port: 80.
7. Backend pool: `be-web`.
8. Health probe: `hp-http`.
9. Session persistence: `None` or `Client IP` depending on requirement.
10. Idle timeout: default 4 minutes or adjust.

Save the rule.

### 7. Test the public load balancer

1. Get the load balancer **public IP** (or configure a DNS name using Azure DNS).
2. Browse to `http://<public-ip>/` from the internet.
3. You should see responses from Web01 and Web02 (you can put different text on each VM to test).

**Exam scenarios to remember:**

- Public load balancer = must have **public frontend** and **NSG rules** to allow inbound traffic on rule ports.
- Standard LB requires NSGs; Basic is open by default.

---

## E. Configure an internal load balancer (ILB)

Scenario: An internal line‑of‑business app should be accessed only from inside the VNet or from on‑prem over VPN. You use an internal Standard Load Balancer.

### 1. Prerequisites

- VNet with an **app subnet** (for example 10.0.2.0/24).
- VMs (App01, App02) in the subnet.
- No public IPs required on the backend VMs.
- NSG that allows the application port from internal sources.

### 2. Create the internal load balancer

1. Portal → **Create a resource** → **Load Balancer**.
2. Type: **Internal**.
3. SKU: **Standard**.
4. Virtual network: select the VNet.
5. Subnet: `AppSubnet` (for the frontend IP).
6. Frontend IP:
   - Give a name, e.g. `fe-app`.
   - Choose **Dynamic** or **Static** private IP (static recommended). citeturn0search14turn0search20

### 3. Backend pool

1. Go to **Backend pools** → **Add**.
2. Name: `be-app`.
3. Add App01 and App02 NICs.
4. Save.

### 4. Health probe

1. **Health probes** → **Add**.
2. Name: `hp-tcp-443` (for HTTPS example).
3. Protocol: TCP.
4. Port: 443.
5. Keep defaults or tune as needed.

### 5. Load‑balancing rule

1. **Load‑balancing rules** → **Add**.
2. Name: `https-internal`.
3. Frontend: `fe-app` (private IP, e.g. 10.0.2.10).
4. Protocol: TCP.
5. Port: 443.
6. Backend port: 443.
7. Backend pool: `be-app`.
8. Probe: `hp-tcp-443`.

### 6. Access pattern

- From other VMs in the same VNet (or peered VNet), use:  
  `https://10.0.2.10/` or better create a Private DNS record like `app.contoso.local` pointing to the ILB IP.
- From on‑prem → route via VPN/ExpressRoute to ILB IP.

**Exam scenario:**

- Internal line‑of‑business web app only accessed from on‑prem office:
  - Use **internal Standard Load Balancer** + **VPN/ExpressRoute** + maybe a **Private DNS** name.

---

## F. Design considerations and best practices

### 1. NSGs and security

- Standard LBs are **secure by default** – they do not allow inbound traffic unless explicitly allowed by NSGs. citeturn2search4turn2search0
- Typical NSG rules:
  - Allow HTTP/HTTPS/RDP/SSH from source (Internet, corporate IP, etc.) to LB frontend subnet or VM subnet.
  - Use the `AzureLoadBalancer` service tag to allow health probe traffic.

### 2. High availability

- Use at least **two backend instances** in **different Availability Zones** (if supported) or in an Availability Set.
- Choose **zone‑redundant** frontends where possible to survive a zone failure.
- For cross‑region failover, combine Load Balancer with **Traffic Manager** or **Front Door**.

### 3. Outbound connectivity and SNAT

- Standard Load Balancer can provide outbound connectivity but SNAT ports are finite.
- For heavy outbound workloads, prefer **Azure NAT Gateway** attached to the subnet to reduce SNAT port exhaustion risk. citeturn0search5turn2search0

### 4. Multiple frontends and port reuse

- You can use **multiple frontend IPs** on one load balancer (multi‑VIP). citeturn0search18turn0search20
- This allows you to:
  - Host multiple public IPs for different applications.
  - Use the same backend pool with different ports or IPs.

### 5. When to choose Load Balancer vs Application Gateway vs Front Door

- **Load Balancer** – Layer 4, TCP/UDP; simple port‑based load balancing inside a region.
- **Application Gateway** – Layer 7 HTTP/HTTPS; supports WAF, URL‑based routing, session affinity with cookies.
- **Front Door** – global anycast entry point, L7, used for global web apps and CDN‑like scenarios.

**Exam hint:** If the question talks about **HTTP path‑based routing**, WAF, SSL offload → think **Application Gateway** or **Front Door**, not Load Balancer.

---

## G. Azure CLI quick examples

### Create a public Standard Load Balancer (simplified)

```bash
# Variables
RG="RG-Web"
LOCATION="westeurope"
LB_NAME="lb-web"
PIP_NAME="pip-web-lb"
VNET_NAME="vnet-prod"
SUBNET_NAME="subnet-web"

# Public IP
az network public-ip create \
  --resource-group $RG \
  --name $PIP_NAME \
  --sku Standard \
  --allocation-method static

# Load balancer
az network lb create \
  --resource-group $RG \
  --name $LB_NAME \
  --sku Standard \
  --public-ip-address $PIP_NAME \
  --frontend-ip-name fe-web \
  --backend-pool-name be-web
```

Then add probe and rule:

```bash
# Health probe on port 80
az network lb probe create \
  --resource-group $RG \
  --lb-name $LB_NAME \
  --name hp-http \
  --protocol Tcp \
  --port 80

# Load balancing rule
az network lb rule create \
  --resource-group $RG \
  --lb-name $LB_NAME \
  --name lbr-http \
  --protocol Tcp \
  --frontend-port 80 \
  --backend-port 80 \
  --frontend-ip-name fe-web \
  --backend-pool-name be-web \
  --probe-name hp-http
```

You don’t need to memorize all parameters, but you should recognize in the exam what this configuration does.

---

## H. Exam tips and patterns

1. **Internal vs Public**  
   - Question mentions **internet clients** → **Public** Load Balancer.  
   - Question mentions **only internal users / on‑prem via VPN** → **Internal** Load Balancer.

2. **Standard vs Basic**  
   - Always choose **Standard** for production / new scenarios.
   - Standard is secure by default and supports advanced features (outbound rules, HA ports, zone‑redundancy).

3. **Health probes**  
   - If a VM is not serving traffic, first check **probe configuration** (protocol, port, path, NSG).  
   - Probes must be able to reach the backend port; otherwise the instance is marked unhealthy.

4. **NSGs and connectivity**  
   - If you cannot reach the frontend IP, verify:
     - NSG rules.
     - Route tables (UDRs) – there must be a path to the subnet.
     - Load‑balancing rule and probe are correctly configured.

5. **RDP/SSH through the Load Balancer**  
   - Use **inbound NAT rules** rather than a load‑balancing rule.

6. **Outbound SNAT issues**  
   - Many outbound connections from NATed workloads → risk of SNAT port exhaustion.  
   - Design fix: add **NAT Gateway** or multiple outbound public IPs.

If you understand these core concepts and can walk through the **public vs internal** configuration steps mentally, you will be well prepared for load balancer questions in AZ‑104.

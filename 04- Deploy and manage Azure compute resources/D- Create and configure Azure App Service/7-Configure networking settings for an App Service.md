# Configure networking settings for an App Service

## A. Overview of App Service networking

Networking for App Service covers **how traffic reaches your app (inbound)** and **how your app reaches other resources (outbound)**.

Key features you must know for AZ‑104: citeturn2search0turn2search2turn2search4

- **Access restrictions** (IP and virtual network rules)
- **Private Endpoints** (Private Link for inbound)
- **VNet integration** (outbound access to resources in a virtual network)
- **Service endpoints** (lock down multitenant endpoints to specific subnets)
- **Hybrid connections** (on‑prem/anywhere TCP access)
- **Public network access** toggle and networking hub in the portal

---

## B. Access restrictions (secure inbound access)

**Access restrictions** work like a firewall for your web app’s public endpoint:

- They define a **priority‑ordered allow/deny list** based on:
  - IP addresses / ranges
  - Azure virtual network subnets (often with service endpoints)
- If any rule exists, an **implicit deny all** is applied at the end of the list. citeturn2search4turn2search3

### Configure access restrictions in the portal

1. Open your **web app** in the portal.
2. Go to **Settings → Networking** (Networking hub).
3. Under **Inbound traffic configuration**, choose **Public network access / Access restrictions**.
4. Add rules:
   - **Allow** from specific IP ranges (e.g., your office WAN IP).
   - **Allow** from selected **virtual network subnets** (requires service endpoints for `Microsoft.Web` in those subnets).
   - Optionally add **Deny** rules with specific priorities.
5. Save.

When a user connects, the **source IP** (or VNet subnet) is evaluated against the rules. If no rule allows it, the service returns **HTTP 403 (Forbidden)**. citeturn2search4

Typical exam scenario:

- “Only allow traffic to the app from Application Gateway subnet and block direct internet access.”  
  → Configure **access restrictions** so only the Application Gateway subnet (with service endpoint to `Microsoft.Web`) is allowed.

---

## C. Private endpoints (private inbound access)

A **private endpoint** assigns a **private IP** from your virtual network to the App Service, via **Azure Private Link**: citeturn2search1turn2search2turn2search8

- Clients in your VNet (and peered networks or via VPN/ExpressRoute) can access the app through this private IP.
- You can disable public network access to ensure the app is reachable **only** via the private endpoint.
- Each deployment slot can have its own private endpoint.

### When to use private endpoints

- Internal line‑of‑business applications that must **not** be publicly accessible.
- Strict compliance or data exfiltration controls.
- Access from on‑premises networks over VPN/ExpressRoute.

### Configure private endpoint (summary)

1. Open the web app → **Networking**.
2. Under **Inbound traffic**, choose **Private endpoints**.
3. Click **Add**:
   - Select a **virtual network** and **subnet**.
   - Confirm DNS settings.
4. Optionally disable **public network access** for the app.

DNS:

- Private endpoints typically use the hostname `myapp.privatelink.azurewebsites.net` and rely on DNS to resolve to private IP. citeturn2search1
- For clients, you configure internal DNS so `myapp.azurewebsites.net` or your custom domain resolves to the private IP.

---

## D. VNet integration (secure outbound access)

**VNet integration** lets your app make **outbound** calls into a virtual network: citeturn2search0turn2search3

- Use it to reach:
  - Private SQL servers or VMs in a VNet.
  - Private endpoints of storage accounts, Key Vault, etc.
  - On‑prem resources via VPN/ExpressRoute connected to that VNet.

Important points:

- VNet integration affects **outbound** traffic only. Inbound traffic still uses the public endpoint (unless you also use private endpoints or an ASE). citeturn2search0turn2search2
- You configure VNet integration per **App Service plan**, using a dedicated **subnet** for integration.
- You can use **route tables** and **NSGs** on this subnet to control outbound traffic.

### Configure VNet integration (portal)

1. Open the web app → **Networking**.
2. Under **Outbound traffic**, select **VNet integration**.
3. Click **Add VNet**.
4. Choose a **virtual network** and a **subnet** for integration.
5. Save.

After integration:

- Traffic to certain routes (depending on configuration routing) goes through the VNet.
- You can use route tables and NSGs to control outbound flows. citeturn2search0

Exam scenario:

> “The app must securely call an Azure SQL Database that is only accessible via private endpoint.”  
**Answer**: Integrate the web app with the VNet and use that VNet to reach the SQL private endpoint.

---

## E. Service endpoints vs private endpoints

Often confused terms in the exam:

- **Service endpoints**
  - Allow a **VNet subnet** to access a multitenant PaaS service over the Azure backbone.
  - For App Service, service endpoints are used together with **access restrictions** to lock down inbound access to specific subnets. citeturn2search4turn2search7

- **Private endpoints**
  - Give the PaaS resource (e.g., web app) a **private IP** in your VNet via Private Link.
  - Inbound traffic comes directly to that private IP.

Quick rule in your head:

- Service endpoints → **subnet‑level restriction** to shared public endpoint.
- Private endpoints → **private IP** per resource, strongest network isolation.

---

## F. Hybrid connections

**Hybrid connections** let your app reach **TCP endpoints** anywhere (on‑prem, VMs, other clouds) by using Azure Relay: citeturn2search2turn2search3

- Requires installing **Hybrid Connection Manager** on a Windows Server that can reach the target resource.
- Good when you can’t use VPN, ExpressRoute, or VNet integration but still need to reach something behind a firewall.

AZ‑104 doesn’t go deeply into Hybrid connections, but you should recognize the term and basic purpose.

---

## G. Public network access toggle & networking hub

Recent portal improvements add a **Networking hub** for App Service: citeturn2search6turn2search10

- Shows a summary of:
  - Public network access status.
  - VNet integration.
  - Private endpoints.
  - IP addresses.
- You can toggle **Public network access** (Allow / Deny) to quickly restrict internet access (often used together with private endpoints).

For the exam, remember that most networking configuration is now surfaced under **Networking** blade of the web app.

---

## H. Common exam scenarios and answers

1. **“Only allow access from specific on‑prem IP ranges”**
   - Configure **access restrictions** with Allow rules for those IP ranges.

2. **“App should only be reachable from a private IP inside the corporate VNet”**
   - Configure a **private endpoint**, update internal DNS, and **disable public network access**.

3. **“App must call an Azure SQL Database via private endpoint, no public access to SQL”**
   - Enable **VNet integration** for the app into the subnet that has the SQL private endpoint.

4. **“Restrict app access so only requests from certain VNet subnets are allowed”**
   - Use **access restrictions** with **virtual network** rules (service endpoints for `Microsoft.Web` enabled on those subnets). citeturn2search4turn2search7

5. **“Need to connect to an on‑premises TCP service, but no VPN/ExpressRoute available”**
   - Use **Hybrid connections**.

---

## I. Best practices

- **Least privilege networking**
  - Don’t expose apps directly to the internet if not needed.
  - Use **private endpoints** and **access restrictions** wherever possible.

- **Use application‑layer security too**
  - Even with private endpoints, use authentication/authorization (e.g., Microsoft Entra ID integration). Network isolation alone isn’t enough. citeturn2search5

- **Monitor connectivity**
  - Use Azure Monitor and **Network Watcher** for diagnostics.
  - Log access restriction events and app logs to detect misconfigurations.

- **Plan address space and subnets carefully**
  - Reserve subnets for VNet integration and private endpoints.
  - Apply NSGs and route tables according to your security design.

If you can differentiate **access restrictions**, **VNet integration**, and **private endpoints**, and know where to configure them, you’re ready for this part of AZ‑104.

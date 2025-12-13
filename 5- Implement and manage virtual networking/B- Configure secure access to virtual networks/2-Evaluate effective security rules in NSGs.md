# Evaluate effective security rules in NSGs

_AZ-104 exam objective: Evaluate and troubleshoot the effective security rules that apply to a VM or subnet._

This file focuses on how Azure **combines NSG rules**, how to read **effective security rules**, and how to troubleshoot using **Network Watcher**.

---

## 1. How NSG rule processing works

Each packet is evaluated against NSGs using a deterministic order.

### 1.1 Direction and scope

For a given flow:

- Azure checks whether it is **Inbound** or **Outbound** relative to the **VM’s NIC**.
- Azure looks at **all relevant NSGs**:
  - NSG on the **subnet**
  - NSG on the **NIC**
- It then evaluates the rules for that direction.

> For a packet to be **allowed**, it must be allowed by **both** the subnet NSG and the NIC NSG. A matching **Deny** in either place blocks traffic.

### 1.2 Rule matching order

Within one NSG (subnet or NIC):  

1. Consider **all rules for the relevant direction** (Inbound or Outbound).
2. Sort rules by **priority** (100 is checked before 200, etc.).
3. For each rule from lowest to highest priority:
   - If **source, destination, protocol, and ports** match the packet, apply the rule’s **Allow/Deny** and **stop**.
4. If **no user-defined rule** matches, fall back to the **default rules** (AllowVNet, AllowLoadBalancer, DenyAll).

Important consequences:

- A **higher-priority allow** (e.g. priority 100) can override a **lower-priority deny** (e.g. priority 400).
- A **higher-priority deny** can override a **lower-priority allow**.

---

## 2. Combining subnet and NIC NSGs (effective behavior)

When **both subnet and NIC** have NSGs, Azure applies an **intersection** of rules:

- For a flow to be allowed:
  - It must be allowed by the **subnet NSG rules**.
  - And also allowed by the **NIC NSG rules**.

If either side denies, the result is **Deny**.

### 2.1 Example 1 – Allow at subnet, no NSG on NIC

- Subnet NSG (`nsg-web-subnet`):
  - Rule 100: Allow TCP 80 from Internet → Any
- NIC: **no NSG**

Result:

- A HTTP request from Internet to the VM:
  - Matches rule 100 (Allow) at subnet level
  - No NIC NSG to restrict it further
  - **Traffic is allowed**

Default rules also apply if no match, but this one matches explicitly.

---

### 2.2 Example 2 – Allow at subnet, Deny at NIC

- Subnet NSG:
  - Rule 100: Allow TCP 80 from Internet → Any
- NIC NSG:
  - Rule 100: Deny TCP 80 from Internet → Any

Result:

- At subnet NSG level: **Allowed**.
- At NIC NSG level: **Denied** (rule 100 matches first).

Final outcome: **Denied**, because NIC NSG blocks it.

> Exam takeaway: Deny anywhere in the chain (subnet/NIC) blocks traffic.

---

### 2.3 Example 3 – Conflicting priorities

Subnet NSG (`nsg-web-subnet`):

- Rule 200: Deny TCP 80 from Internet → Any

NIC NSG (`nsg-web-vm1`):

- Rule 100: Allow TCP 80 from Internet → Any

Request: HTTP from Internet to VM.

Evaluation:

- Subnet NSG: only has one relevant rule → Deny at priority 200.
- NIC NSG: Allow at priority 100.

Even though the NIC rule has a **lower priority number**, you **must pass both NSGs**. The subnet NSG still **denies** the packet, so final result is **Denied**.

> Rule priority is **only meaningful inside a single NSG**. You never merge rules from two NSGs into one list; each NSG decides independently, then results are combined.

---

## 3. Viewing effective security rules in the Azure portal

When troubleshooting a VM, the portal can show you the **combined result** of subnet + NIC NSGs.

### 3.1 How to see effective security rules

1. Go to **Virtual machines** → select a VM.
2. Go to **Networking**.
3. Under the NIC, click **View effective security rules** (or **Effective security rules** link).

Azure will show:

- Direction (Inbound/Outbound)
- Source / Source port
- Destination / Destination port
- Protocol
- Access (Allow/Deny)
- Priority
- Which NSG the rule came from (subnet or NIC)

This table already reflects the **effective** result of combining subnet and NIC NSGs.

### 3.2 How to read the effective rules

- Look for the **most specific rule** that matches your scenario.
- Confirm whether the access is **Allow** or **Deny**.
- Check whether the rule originates from **subnet NSG** or **NIC NSG**.

If something is unexpectedly blocked:

- Look for a **Deny rule** that matches your traffic (inbound/outbound).
- Pay attention to **priority** – a Deny with a low priority number stops evaluation early.

---

## 4. Using Network Watcher to evaluate NSG behavior

**Azure Network Watcher** provides tools to test traffic and see exactly **which NSG rule** is causing an Allow or Deny.

### 4.1 IP flow verify

**IP flow verify** simulates traffic to/from a VM and tells you:

- Whether the traffic is **Allowed** or **Denied**
- Which **NSG rule** made the decision

Steps:

1. In the portal, search for **Network Watcher**.
2. In the region of interest, select **IP flow verify**.
3. Provide:
   - Subscription
   - Resource group
   - VM
   - Direction (Inbound/Outbound)
   - Protocol (TCP/UDP)
   - Local IP / Local port
   - Remote IP / Remote port
4. Click **Check**.

Output example:

- Access: `Deny`
- Rule: `Deny-RDP-From-Internet`
- NSG: `nsg-web-subnet`

This is extremely useful when the exam describes **tools for troubleshooting connectivity**.

### 4.2 NSG flow logs

**NSG flow logs** record allowed/denied flows to a storage account and can be visualized in Azure Monitor or external tools.

High-level steps:

1. Enable **Network Watcher** in the subscription.
2. In Network Watcher → **NSG flow logs**.
3. Select NSG → enable flow logs → choose storage account and retention.
4. Use **Traffic Analytics** or Log Analytics workspace queries to analyze patterns.

You likely won’t be asked to write Kusto queries in AZ‑104, but you should know **what NSG flow logs are used for**:

- Audit who talks to whom
- Troubleshoot unexpected blocks
- Confirm that your NSG rules behave as intended

---

## 5. Working through example rule sets

The exam often gives you tables of rules and asks “Is this allowed or denied?”

### 5.1 Example – RDP access from specific admin IP

**Subnet NSG (`nsg-management-subnet`) – Inbound rules**

| Priority | Name                | Source IP        | Dest | Port | Protocol | Action |
|----------|---------------------|------------------|------|------|----------|--------|
| 100      | Allow-RDP-From-Admin| 203.0.113.10/32  | Any  | 3389 | TCP      | Allow |
| 200      | Deny-RDP-From-Internet | Internet    | Any  | 3389 | TCP      | Deny  |
| 65000    | AllowVNetInBound    | VirtualNetwork   | VNet | *    | Any      | Allow |
| 65500    | DenyAllInBound      | *                | *    | *    | Any      | Deny  |

**Question:** A connection from `203.0.113.10` to a VM on port 3389?

Evaluation:

1. Rule 100: Source matches (203.0.113.10), port 3389, TCP → **Allow** → stop.
2. Rule 200 is never evaluated for that flow.

**Answer:** Allowed.

---

### 5.2 Example – Web server blocked by NIC rule

**Subnet NSG (`nsg-web-subnet`) – Inbound rules**

| Priority | Name                     | Source       | Port | Action |
|----------|--------------------------|--------------|------|--------|
| 100      | Allow-HTTP-From-Internet | Internet     | 80   | Allow |
| 110      | Allow-HTTPS-From-Internet| Internet     | 443  | Allow |
| 65500    | DenyAllInBound           | *            | *    | Deny  |

**NIC NSG (`nsg-vmweb01`) – Inbound rules**

| Priority | Name              | Source   | Port | Action |
|----------|-------------------|----------|------|--------|
| 100      | Deny-All-Inbound  | *        | *    | Deny  |

**Question:** Can a user browse to `vmweb01` over HTTPS (443) from Internet?

- Subnet NSG: rule 110 allows HTTPS.
- NIC NSG: rule 100 denies all inbound before any allow rule.

Final: **Denied**.

---

### 5.3 Example – Outbound flow blocked

**NIC NSG – Outbound rules**

| Priority | Name                | Destination | Port | Action |
|----------|---------------------|-------------|------|--------|
| 100      | Deny-Internet-443   | Internet    | 443  | Deny  |
| 65000    | AllowVNetOutBound   | VNet        | *    | Allow |
| 65001    | AllowInternetOutBound| Internet   | *    | Allow |

Question: Can the VM connect to `https://www.microsoft.com` (TCP 443)?

- Outbound traffic to Internet on port 443:
  - Matches rule 100 → **Deny**.
  - Lower priority allow rules are ignored.

Final: **Denied** even though default `AllowInternetOutBound` exists.

---

## 6. Interaction with other components (high-level)

### 6.1 NSG vs Route table vs Azure Firewall

For outbound traffic from a NIC:

1. **NSG** decides whether traffic is allowed/denied at the NIC/subnet.
2. If allowed, **user-defined routes (UDRs)** decide where to send traffic (Internet, VPN, Firewall, etc.).
3. If traffic goes through **Azure Firewall/NVA**, that device may also allow/deny.

For the exam:

- NSGs = security rules at NIC/subnet.
- Route tables = choose the **next hop** (Internet, VPN, VNet peering, Firewall).
- Azure Firewall = stateful firewall at network DMZ.

All three can block traffic, but for AZ‑104 you mainly focus on **NSGs for access control at the VNet level**.

---

## 7. Best practices and exam tips

- Always remember: **lower priority number → processed earlier**.
- The first rule that matches decides; list order in portal UI is not what matters, **priority** is.
- If subnet and NIC NSGs exist, the effective behavior is **more restrictive** (logical AND).
- Use **Effective security rules** view when asked how to confirm which rules apply to a VM.
- Use **Network Watcher IP flow verify** when asked how to test whether traffic should be allowed or denied by NSGs.
- Use **NSG flow logs** when asked about analyzing real traffic patterns or auditing network flows.
- If something is unexpectedly blocked, look for:
  - A **Deny** rule with low priority in subnet or NIC NSG.
  - A missing **Allow** rule that would have matched before the default deny.

If you can read NSG rule tables confidently and simulate the evaluation process in your head, you’ll be in a strong position for this part of AZ‑104.

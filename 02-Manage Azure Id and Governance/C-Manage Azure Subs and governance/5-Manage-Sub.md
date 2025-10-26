# Manage Subscriptions

## Azure Subscription Basics

### What is a subscription?

- It's a billing boundary: defines who pays and how much.
- It's also a container for resources: all Azure resources (VMs, storage, etc.) live inside a subscription.

### Relationship with tenant and account

- Tenant = your Microsoft Entra ID (identity boundary).
- Subscription = resource & billing boundary.
- Account = the identity that owns the subscription (like your email / Microsoft account / org account).
- 1 tenant can have many subscriptions.
- A subscription is always linked to one tenant.

---

## Subscription Types

### Free Trial

- Limited time (usually 30 days).
- Limited credit (e.g., $200).
- Convert to Pay-As-You-Go if you want to keep using.

### Pay-As-You-Go (PAYG)

- Most common.
- Personal/individual use.
- Billed monthly for actual usage.

### Enterprise Agreement (EA)

- For large organizations.
- Pre-negotiated pricing/discounts with Microsoft.
- Consolidated billing for many subscriptions.

### Cloud Solution Provider (CSP)

- You buy through a Microsoft partner.
- Partner manages billing and sometimes support.
- Often used by small/medium businesses.

**Key exam points to remember:**
- Subscription = billing + resource boundary.
- Tenant = identity boundary.
- Account = owner/creator of subscription.
- Types = Free Trial, Pay-As-You-Go, Enterprise Agreement, CSP.
- Know differences in billing: Free = limited credit, PAYG = per use, EA = org-level discounts, CSP = partner-managed.

---

## Subscription Identity & Ownership

- Subscription always tied to one tenant (directory).
- The tenant = Microsoft Entra ID directory.
- Subscription can only trust one tenant at a time.

### Change directory (move subscription between tenants)

You can move a subscription to another tenant, but only if:
- Both tenants allow it.
- Some services may not move cleanly (limitations).
- Useful when orgs merge/split or you need to consolidate under one tenant.

---

## Roles Related to Subscriptions

### Classic Roles (older model, subscription-wide only)

**Account Administrator (AA):**
- Created when the subscription is created.
- Has full control over billing (can change payment methods, view invoices, cancel subscription, etc.).
- Can also assign/change the Service Administrator.
- Default = the person who created the subscription.

**Service Administrator (SA):**
- By default, the same person as the Account Admin (but AA can change it).
- Has full control over all resources in the subscription (like an RBAC Owner).
- No access to billing unless the AA also makes them a Billing Admin in the account portal.
- So yes, SA cannot touch billing unless AA gives them permission.

**Co-Administrator:**
- Assigned by the Service Admin or Account Admin.
- Can have up to 200 co-admins per subscription.
- Has the same rights as the Service Admin (full control over resources).
- No control over billing (same restriction as SA).

**⚠️ Note:** These are classic roles, still appear in exam questions.

**Quick Summary:**
- AA → billing + can assign SA.
- SA → full control of resources, no billing.
- Co-Admin → same as SA, no billing, max 200.

### RBAC Roles (modern, resource-based)

- Applied at scope: subscription, RG, or resource.

**Common roles:**
- Owner → full access + manage access.
- Contributor → create/manage resources (but can't assign roles).
- Reader → view only.
- Billing Reader → view billing data but not change resources.

### Billing vs Resource Administrators

- Billing Administrator → manages billing (in Azure portal's "Cost Management + Billing"), not resources.
- Resource Administrator (Owner/Contributor in RBAC) → manages services/resources, not billing.

**Exam tips to remember:**
- Subscription = tied to 1 tenant.
- You can move it between tenants, but with conditions.
- Classic roles: Account Admin, Service Admin, Co-Admin.
- RBAC roles: Owner, Contributor, Reader, Billing Reader.
- Billing admin ≠ Resource admin (two separate responsibilities).

---

## Subscription Management Operations

### Rename a subscription

- Purely cosmetic (for easier identification).
- No impact on resources, billing, or IDs.

### Move a subscription to a different Azure AD tenant

Possible, but with limitations:
- Some resources/features may not move.
- User access & RBAC assignments reset (you'll need to reassign after move).
- Both tenants must allow the move.

### Transfer subscription ownership (billing)

- Example: employee leaves, company needs new billing owner.
- Done via Azure portal → Cost Management + Billing.
- Transfers the billing relationship, not resources themselves.

### Cancel or re-enable a subscription

- Cancel → stops future billing, resources eventually deleted (after retention period).
- Re-enable → possible if you restart within grace period.

**Exam checklist:**
- Rename = cosmetic.
- Move subscription = resets access, limited by resource support.
- Transfer ownership = billing side.
- Cancel/Re-enable = billing + resource lifecycle.
- Subscription scope = permissions flow down.
- Best practice = subscription-level roles only for admins.

---

## Scopes & Inheritance

### Subscription scope

- RBAC roles assigned here apply to all resource groups and resources inside it.
- Example: Owner at subscription = Owner everywhere in that subscription.

### Inheritance

- Role assignments flow downward (subscription → RG → resource).
- Child scopes can have additional roles but not fewer unless Deny assignment (rare).

### Best practice

- Assign roles at subscription level only to true admins (e.g., central IT).
- For regular users/teams → assign at RG or resource level for least privilege.

---

## Governance with Multiple Subscriptions

### Why use multiple subscriptions?

- Billing separation → different departments, projects, or customers.
- Compliance / policy isolation → apply policies per subscription (e.g., EU vs US data rules).
- Environment separation → dev / test / prod in different subscriptions for safety.
- Quota & limits → each subscription has its own limits (VM cores, storage, etc.), so more subscriptions = more capacity.

### Management Groups

- Tool to group multiple subscriptions into a hierarchy.
- Governance applies at the management group level, flows down to subscriptions.
- Example: assign a policy or RBAC role at root management group → applies to all subscriptions under it.

---

## Costs & Billing

### Billing scope

- Subscription = smallest billing unit.
- Billing account = higher level, might contain many subscriptions (e.g., in an Enterprise Agreement).

### Cost Management

- You can link subscriptions to Cost Management to track spend.
- View costs by subscription, RG, or even tag (like Dept = Finance).

### Budgets & Alerts

- Create budgets at subscription level.
- Example: set $500 budget → send alerts when 80% is reached.
- Alerts do not stop resources, they just notify.
- Can be combined with automation (like Logic Apps or Functions) to take action if needed.

**Exam must-knows:**
- Multiple subscriptions = billing, compliance, environment, capacity reasons.
- Management Groups = organize & apply governance across subscriptions.
- Billing scope: subscription vs billing account.
- Budgets & alerts = notify, not enforce (unless automated).
# Configure Management Groups

## Purpose of Management Groups

- Organize multiple subscriptions into a hierarchy.
- Apply governance consistently (Azure Policy, RBAC, budgets, cost mgmt).
- Useful when you have many subscriptions (enterprise setups, multiple environments).

---

## Hierarchy Structure

### Root Management Group

- Created automatically for the tenant.
- Cannot be deleted/renamed.
- All management groups and subscriptions roll up under it.

### Subscriptions

- Each subscription must belong to one management group.

### Nesting

- You can create child management groups under others.
- Maximum 6 levels deep (not counting the root).

### Example Hierarchy

```
Tenant (Azure AD)
   │
   └── Root Management Group (auto-created, can't delete)
         ├── MG: Production
         │      ├── Subscription: Prod-Sub1
         │      └── Subscription: Prod-Sub2
         │
         ├── MG: Development
         │      └── Subscription: Dev-Sub1
         │
         └── MG: Finance
                └── Subscription: Finance-Sub1
```

### Example with Nested Management Groups

```
Root Management Group
   ├── MG: Production
   │      ├── MG: Prod-Europe
   │      │        └── Subscription: EU-Prod-Sub
   │      └── MG: Prod-US
   │               └── Subscription: US-Prod-Sub
   │
   └── MG: Development
          └── MG: Dev-Test
                 └── Subscription: Dev-Sub
```

**✅ Key Exam Notes:**
- Root MG = always there, can't delete.
- Subscriptions → must be under a management group.
- Nesting depth = 6 levels (excluding root).
- Governance (policies, RBAC, budgets) can be applied at any level, flows down to all children.

---

## Scope & Inheritance

- You can assign Azure Policy or RBAC roles at the management group level.
- These assignments inherit downward:
  - Management Group → Subscriptions → Resource Groups → Resources.
- This lets you apply governance once at a higher level instead of repeating it for each subscription.

---

## Access Control (RBAC)

- You can assign roles (Owner, Contributor, Reader, etc.) at the management group level.
- Example: Give "Reader" at MG level → user is Reader for all subscriptions & resources under it.
- Permissions flow down automatically, same as subscription → RG → resources.

**✅ Key Exam Notes:**
- Management Group = top scope (above subscription).
- Inheritance = automatic (no need to reapply at child scopes).
- Use MG-level RBAC to control access at scale.
- Great for large orgs with multiple subscriptions (governance consistency).

---

## Governance & Best Practices

### Organize subscriptions logically

- By environment → Production, Dev/Test, Sandbox.
- By department or business unit → Finance, HR, IT, Sales.

### Apply policies and security baselines at the top level

- Apply at root MG or parent MG.
- Ensures consistency for compliance, security, and cost control.

### Use naming standards

- For management groups (e.g., Prod-MG, Dev-MG).

### Keep least privilege in RBAC

- Assign broad roles only when necessary.

---

## Limits & Constraints

- One tenant = one root management group (automatic, can't delete).
- 10,000 management groups max per directory.
- A subscription can only belong to ONE management group at a time.

### Moving subscriptions between MGs

- Needs Owner/Contributor role on both source and target MG.
- Some temporary access restrictions may apply during the move.

**✅ Key Exam Notes:**
- Root MG is unique per tenant.
- Subscriptions are exclusive (only one MG at a time).
- Max 10k management groups (unlikely in exam labs, but must know).
- Always organize by environment or department for clarity + governance.
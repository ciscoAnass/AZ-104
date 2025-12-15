# Implement and Manage Azure Policy

## A. Azure Policy Basics

### Definition

Azure Policy = Governance tool in Azure.
It enforces rules on resources so everything follows company standards.
Think: "what can/can't exist" in Azure.

### Purpose

Ensure compliance with rules.

**Examples:**
- Enforce naming conventions (must start with dept-).
- Restrict locations (only West Europe).
- Limit VM sizes (only B2s, D2s).
- Require tags (CostCenter = IT).

### Azure Policy vs RBAC

| Aspect | RBAC | Policy |
|--------|------|--------|
| Controls | WHO can do WHAT (permissions) | WHAT can be created/used (compliance rules) |

**Together:**
- RBAC says: "You can create VMs."
- Policy says: "But only in West Europe and only B2s size."

### Components of Azure Policy

**Policy Definition**
- The rule itself.
- Example: "Allowed locations = [West Europe, North Europe]."

**Policy Assignment**
- Where you apply the rule: subscription, resource group, or management group.

**Initiative (Policy Set)**
- Collection of multiple policies grouped together.
- Example: "Security baseline" initiative = tagging + encryption + allowed locations.

**Parameters**
- Make policies reusable.
- Example: AllowedLocations = ["West Europe", "North Europe"].

### Effects (what policy does)

**1. Deny**
- Stop right away.
- If the resource doesn't follow the rule → Azure won't let you create it.
- Example: Policy = "VMs must be in West Europe." → You try to make a VM in East US → blocked ❌.

**2. Audit**
- Just warn you.
- The resource is created, but marked as non-compliant.
- Example: Policy = "All resources must have a CostCenter tag." → You make a VM without the tag → It still works, but Azure flags it as non-compliant.

**3. Append**
- Adds missing settings automatically.
- Example: Policy = "All resources must have a tag = Department:IT." → You make a VM without tags → Azure automatically adds the tag for you.

**4. Modify**
- Changes the resource to match the rule.
- Example: Policy = "Storage accounts must use HTTPS." → You make one with HTTP only → Azure will fix it to use HTTPS.

**5. AuditIfNotExists**
- Check if something exists. If not → just warn you.
- Example: Policy = "VMs must have backup enabled." → You create a VM without backup → Azure will flag it as non-compliant.

**6. DeployIfNotExists**
- Check if something exists. If not → Azure will create it for you.
- Example: Policy = "VMs must have monitoring enabled." → You create a VM without monitoring → Azure will automatically deploy monitoring on it.

**Exam tip:**
- Deny = block
- Audit = allow but flag
- Append = add missing setting
- Modify = fix wrong setting
- AuditIfNotExists = warn if missing
- DeployIfNotExists = fix by creating

### Scope & Inheritance

- Can assign at: Management group → Subscription → Resource group → Resource.
- Policies inherit down (like RBAC).
- Example: Assign "Allowed locations" at subscription → applies to all resource groups and resources inside.

### Compliance

- Azure Policy continuously evaluates compliance.
- Portal shows Compliant vs Non-compliant resources.
- You can trigger a remediation task to fix non-compliant resources (if effect supports it).

**Exam tip:**
- Remember Policy = compliance guardrails.
- RBAC ≠ Policy (permissions vs governance).
- Know effects and initiative = collection of policies.
- Always linked to management groups/subscriptions/resource groups for inheritance.

---

## B. Azure Policy Structure

### 1. Definition

- A definition is the rule written in JSON (the code).
- It describes what is allowed or denied.
- Example JSON idea:

```json
{
  "if": {
    "field": "location",
    "notIn": ["West Europe", "North Europe"]
  },
  "then": {
    "effect": "deny"
  }
}
```

This says: "If location is not West/North Europe → Deny."

### 2. Assignment

- A policy doesn't work until you assign it.
- Assignment = where you apply the rule.
- Scope can be:
  - Management group
  - Subscription
  - Resource group
  - Resource

**Example:**
You have a "West Europe only" rule.
- Assign it at Subscription → applies to everything there.
- Assign it at Resource Group → only applies inside that group.

### 3. Parameters

- Parameters = variables in the policy.
- They make the policy flexible and reusable.
- Instead of hardcoding values, you leave a placeholder.

**Example:**
- Policy definition: "Allowed locations = parameter allowedLocations."
- When assigning, you can set:
  - Sub1 → allowedLocations = West Europe
  - Sub2 → allowedLocations = East US

So the same rule works in different places with different values.

**Exam tip:**
- Definition = the rule (JSON).
- Assignment = where to apply the rule (scope).
- Parameters = make it flexible (change values without rewriting).
- Effects = what happens (Deny, Audit, Modify, DeployIfNotExists).

---

## C. Initiatives

### What is an Initiative?

- An initiative = a group of policies bundled together.
- Instead of assigning 10 separate policies, you put them inside 1 initiative and apply it once.
- Think of it like a folder of rules.

### Example

**Initiative: "Hospital Security Rules"**

Contains:
- Only West Europe is allowed.
- Every VM must have tag Hospital=ITDesk.
- VM names must start with vm-.
- Storage accounts must use HTTPS only.

Now, instead of assigning 4 policies separately → you assign 1 initiative.
✅ Easier to manage, easier to report compliance.

---

## D. Scope & Inheritance

**Scope = where you apply the rule**
- Management group → applies to all subscriptions inside.
- Subscription → applies to everything in that subscription.
- Resource group → applies to everything in that group.
- Resource → only that specific VM, DB, storage, etc.

**Inheritance = rules flow down**
- If you apply at a higher level, it flows down automatically.
- Example: Assign "West Europe only" at Subscription → All resource groups + all resources inside → must be in West Europe.

**Exclusion (exception)**
- You can exclude specific resource groups or resources if needed.
- Example: You assign "West Europe only" at subscription level, but exclude one resource group → that group can create resources anywhere.

**Exam tip:**
- Initiative = group of policies.
- Scope = where rule applies.
- Inheritance = flows down from bigger scope → smaller scope.
- Exclusions = make exceptions.

---

## E. Built-in vs Custom Policies

### Built-in Policies

- Made by Microsoft.
- Ready to use, no need to write JSON.
- Common rules most companies need.
- Examples:
  - Allowed locations.
  - Allowed VM sizes.
  - Require tag.
  - Storage must use HTTPS.

### Custom Policies

- Made by you (the admin).
- Written in JSON.
- Used when Microsoft doesn't have the exact rule you need.
- Examples:
  - Every VM name must start with vm-.
  - Resource group names must start with rg-.
  - Databases must start with db-.

**Exam tip:**
- Built-in = Microsoft rules (ready to go).
- Custom = Your own rules (written in JSON).
- Compliance = Azure checks and shows green/red.
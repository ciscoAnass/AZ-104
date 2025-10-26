# Interpret Access Assignments

## A. Role Assignment Formula

A role assignment always = **WHO + WHAT + WHERE**

### WHO → Security Principal

The identity that gets permissions:
- **User** (an employee)
- **Group** (collection of users)
- **Service principal** (app registration)
- **Managed identity** (identity given to Azure service like VM, Function, etc.)

### WHAT → Role Definition

The set of permissions:

Example: Owner, Contributor, Reader, User Access Administrator

Each role = list of allowed Actions (and sometimes denied NotActions).

### WHERE → Scope

The level the role applies at:
- **Management group** → top, multiple subscriptions
- **Subscription** → applies to all resource groups/resources inside
- **Resource group** → applies to all resources inside that group
- **Resource** → applies to just that one VM, storage account, etc.

### How It Works

A role assignment links the three together.

**Example:**
Assign Contributor (role) to Alice (user) at Resource Group "DevRG" (scope).

**Key Concepts:**
- Permissions flow downward (inheritance): higher scope applies to everything below
- You can have multiple role assignments → permissions combine (additive)

### Exam-Level Key Points

- **Security principal** = the "identity"
- **Role definition** = the "permissions"
- **Scope** = the "location"
- **Inheritance (downward)** = permissions trickle down, but not up
- **Combining** = if a user has multiple roles, Azure adds them together
- **Least privilege principle** → always assign the minimum role needed

---

## B. Check Effective Permissions

### 1. Effective Permissions = UNION

Azure calculates a user's final access by combining (union) all roles assigned.

**Example:**
- Reader at Subscription
- Contributor at Resource Group

👉 **Effective permissions** = Reader everywhere + Contributor in that Resource Group

### 2. Higher Scope Flows Downward

If a role is assigned at Subscription scope, it flows down to all resource groups/resources.
Unless a more powerful role is given at a lower scope.

**Example:**
- Subscription: Reader
- Resource Group: Contributor

👉 Inside that RG, Contributor overrides Reader. Everywhere else, still Reader.

### 3. Deny Assignments

Rare (Microsoft creates them, you usually don't). They block access even if you have a role.

**Example:**
- User = Contributor on Storage Account
- Deny assignment says "cannot delete blobs"

👉 Even though Contributor normally allows delete, the deny wins.

Think of it as a "hard stop" — **deny > allow**.

### Exam-Level Key Points

- **Effective permissions** = ALL assignments combined across all scopes
- **Inheritance** = higher → lower, but lower scope can add more
- **Deny assignments** = absolute block (rare, system-created)
- **Always apply least privilege** when interpreting results

### Easy Example

Bob has:
- Reader at Subscription
- Contributor at Resource Group "DevRG"
- Deny assignment on "delete VM"

👉 **Effective permissions:**
- Everywhere → Reader
- Inside DevRG → Contributor (but cannot delete VMs, because deny wins)

**Exam Shortcut:**
Effective Permissions = UNION of all allows – any denies

---

## C. Role Assignment Sources

### 1. Direct Assignment

Role assigned directly to the user.

**Example:**
Alice is explicitly given Reader at a Storage Account.

- ✅ Easy to manage for one person
- ❌ Hard to scale for many users

### 2. Group Assignment

Role is assigned to a group instead of individuals. All group members inherit that role.

**Example:**
DevTeam group = Contributor at Resource Group → every member gets Contributor there.

- ✅ Best practice for scalability and easier management

### 3. Inherited Assignment

If a role is assigned at a higher scope, it flows down.

**Example:**
Bob has Reader at Subscription → he can read all resource groups and resources inside.

- ✅ Saves time (don't need to re-assign at every lower level)

### 4. PIM (Privileged Identity Management) Assignment

Special feature (Microsoft Entra ID P2). Provides just-in-time (JIT) and temporary role elevation.

**Example:**
Sarah is a normal user, but can activate Owner role for 2 hours via PIM.

- ✅ Reduces risk by not keeping users permanently privileged

### Exam-Level Key Points

- **Direct vs Group** → Know the difference!
- **Inheritance** → Always flows downward (MG → Subscription → RG → Resource)
- **PIM** → For temporary, time-bound, or approval-based access
- **Best practice** = Group assignment + PIM → avoids "role sprawl" and ensures least privilege

### Easy Real-Life Example

Alice has:
- Reader at Subscription (direct assignment)
- Member of DevOpsGroup, which = Contributor at Resource Group (group assignment)
- Contributor applies inside DevRG (group), Reader applies everywhere else (inherited from subscription)
- If she needs Owner rights for 1 hour → she requests via PIM

**Remember:**
- **Direct** = one person
- **Group** = many people at once
- **Inherited** = trickle down
- **PIM** = temporary / on-demand

---

## D. Access Evaluation Tools

### 1. Azure Portal

**Tool:** Check Access

**Path:** Go to the resource → Access control (IAM) → Check access

**Shows:**
- What roles the user/service principal has
- At what scope (subscription, RG, resource)
- Whether it came from direct, group, or inherited assignment

✅ Best for quick visual check in the portal

### 2. Azure CLI

**Command:**
```bash
az role assignment list --assignee <userUPN_or_objectId>
```

**Shows:**
- All role assignments for that user
- Scope (subscription, RG, resource)
- Role definition (e.g., Contributor, Reader)

✅ Useful for scripting and automation

### 3. PowerShell

**Command:**
```powershell
Get-AzRoleAssignment -SignInName <userUPN>
```

**Shows:**
- Same info: roles, scope, assignment source

✅ Preferred if your environment uses PowerShell for Azure management

### Exam-Level Key Points

- **Portal** = IAM → Check Access (GUI way)
- **CLI** = `az role assignment list --assignee` (scripting)
- **PowerShell** = `Get-AzRoleAssignment` (admin automation)

All of them display:
- Roles assigned
- Scope
- Source (direct, group, inherited, PIM)
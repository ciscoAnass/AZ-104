# Assign Roles at Different Scopes

## A. Scopes

Think of scopes as "where" your role permissions apply. Azure has 4 levels:

### 1. Management Group

🔝 **Highest level**

Used to group multiple subscriptions under one umbrella. If you assign a role here → it flows down to all subscriptions, then to all their resource groups, then to all resources.

**Example:**
Assign Reader at management group → user can view everything in all subscriptions under it.

### 2. Subscription

One level below management group. Covers all resources in that subscription. If you assign a role here → it applies to every resource group and resource inside this subscription.

**Example:**
Assign Contributor at subscription → user can create/manage any resource inside.

### 3. Resource Group

Smaller container inside a subscription. Covers all resources inside that group only. If you assign a role here → user gets access to everything in that group, but not in other groups.

**Example:**
Assign Virtual Machine Contributor at resource group → user can manage VMs in that group only.

### 4. Resource

🎯 **Most specific scope**

Applies to one single resource (VM, storage account, database, etc.). Use when you want to restrict access very tightly.

**Example:**
Assign Storage Blob Data Reader only to one storage account.

### Key Points for Exam

- **Inheritance:** Permissions flow down (Management group → subscription → resource group → resource)
- **Least privilege:** Always assign at the lowest scope needed
- **Scope levels in order:**
  - Management group = entire company
  - Subscription = one department's Azure bill
  - Resource group = one project/app
  - Resource = single VM or storage account

---

## B. Inheritance of Role Assignments

### Flow of Permissions

Role assignments always flow downward (from parent scope to child scopes).

**Examples:**
- Assign Reader at subscription → user can view all resource groups and all resources inside it
- Assign Contributor at resource group → applies to all resources inside that group

### Combining Permissions

If a user has multiple roles (from different scopes), Azure merges them.

**Example:**
- User = Reader at subscription
- User = Contributor at one resource group
- Result → In that resource group, user is Contributor. In the rest of the subscription, user is Reader.

### Override vs Add

Lower scope role can override/add to higher scope.

**Example:**
- Higher scope: Reader at subscription
- Lower scope: Owner at one resource group
- Result → User is Owner in that resource group, but only Reader in other groups

### Key Exam Takeaways

- **Inheritance is always top → down**
- **No upward flow** (permissions don't go back up)
- **Multiple roles = union of permissions** (most permissive wins)
- **Always apply least privilege** and use lowest scope possible

---

## C. When to Assign Roles at Each Scope

### 1. Management Group

🎯 **Use when** you want consistency across multiple subscriptions

Good for enterprise-wide policies (security, compliance, auditors).

**Example:**
Assign Reader at management group → security team can view everything in all subscriptions.

### 2. Subscription

🎯 **Use for** broad control across one subscription

Good for subscription admins, billing owners, central IT teams.

**Example:**
Assign Contributor at subscription → IT staff can manage any resource inside that subscription.

### 3. Resource Group

🎯 **Use for** project or team-level control

Fits well with how resources are usually grouped by project/app.

**Example:**
Assign Virtual Machine Contributor at RG → dev team can manage all VMs in their project, but nothing else.

### 4. Resource

🎯 **Use for** very specific or unique cases

Good when you need fine-grained access for a single resource.

**Example:**
Assign Storage Blob Data Reader → user can read blobs only in one storage account.

### Exam Takeaways

- **Higher scope** = wider inheritance (flows down)
- **Lower scope** = least privilege (only what's needed)
- **Best practice** → always assign at the lowest scope that meets the need

---

## Best Practices

- Follow least privilege: assign the smallest scope needed
- Use groups for role assignments instead of individual users
- Use built-in roles unless you need custom
- Review assignments regularly to avoid privilege creep
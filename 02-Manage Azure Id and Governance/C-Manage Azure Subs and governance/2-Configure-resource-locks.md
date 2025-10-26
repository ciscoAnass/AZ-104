# Configure Resource Locks

## A. Purpose of Resource Locks

Protects critical Azure resources from accidental deletion or modification.
Example: You don't want someone to accidentally delete a production VM or storage account.

### Lock Types

**ReadOnly**
- Can only read/view the resource.
- No create, update, or delete allowed.
- Acts like giving everyone "Reader" access, even if they normally have higher permissions.

**CanNotDelete**
- Allows read and modify/update, but cannot delete the resource.
- Protects resources from being deleted, but they can still be changed.

### Scope of Locks

Can apply at different levels:
- Subscription → applies to everything inside it.
- Resource group → applies to all resources inside the group.
- Resource → applies to just that one resource.

**Inheritance:** Locks apply downwards.
Example: Lock on a Resource Group → all VMs, Storage, etc. inside it are locked.

### Who Can Manage Locks

- Only Owner or User Access Administrator roles (or equivalent custom RBAC role with permission).
- Contributor cannot remove a lock unless given that permission.

### Where to Configure

- Azure Portal → Settings → Locks.
- Azure CLI → az lock create.
- PowerShell → New-AzResourceLock.

### Best Practices

- Use locks on production resources (VMs, storage, databases).
- Do not overuse locks (can block automation scripts).
- Remember: Locks override RBAC. Even if you have "Owner" role, you cannot delete a locked resource without first removing the lock.

**Exam Tip:**
If a resource is locked, nobody can bypass the lock with permissions alone. You must remove the lock first.

---

## B. Behavior & Limitations

### Locks override RBAC

- Even if you are an Owner, you cannot delete/modify a locked resource.
- You must remove the lock first.

### Some operations still possible

- Example: Moving a locked resource to another resource group might still succeed (depending on lock type and resource).
- Important: Locks don't block all operations, only the restricted ones (delete / modify depending on lock type).

### Explicit removal needed

- To perform restricted actions (like delete), you must manually remove the lock first.

**Exam Tip:** If the question says:
"An Owner cannot delete a VM. Why?" → Answer: Because a resource lock (CanNotDelete) is applied.
Locks always win against RBAC roles until removed.
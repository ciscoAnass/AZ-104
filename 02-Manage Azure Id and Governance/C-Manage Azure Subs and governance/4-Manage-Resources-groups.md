# Manage Resource Groups

## A. Resource Group Basics

### What is a Resource Group (RG)?

- A logical container in Azure.
- Used to organize and manage resources like VMs, storage, databases, networks, etc.
- Think of it as a folder for your Azure resources.

### Lifecycle Management

- If you delete a resource group, all resources inside it are automatically deleted.
- Makes cleanup easy → but also risky if done by mistake.

### Resource Membership

- Every resource must belong to exactly one resource group.
- You cannot place a resource in two groups at the same time.
- However → resources in different groups can still communicate (e.g., a VM in RG1 can connect to a DB in RG2).

### Scope & Boundaries

- A resource group always exists within a single subscription.
- Cannot span multiple subscriptions.
- So → Subscription > contains many Resource Groups > each RG contains many resources.

**Exam tip:**
Remember the hierarchy:
Management Group → Subscription → Resource Group → Resource.
RGs are the third level, and deleting them = wipes everything inside.

---

## B. Resource Group Operations

### Basic Operations

- You can create, update, move, or delete resource groups.
- If you delete an RG → all resources inside are deleted too.

### Moving Resources

You can move resources:
- Between resource groups (same subscription).
- Between subscriptions (sometimes allowed).

**Limitations/Constraints:**
- Not all resource types can be moved.
- Some resources have dependencies (e.g., VM + NIC + Disk must move together).
- Certain services (like Azure AD objects) cannot be moved at all.
- During the move, resources might be locked temporarily.

### Location of RG vs Location of Resources

- A Resource Group has its own location (region).
- This is where the metadata about the RG and resources is stored.
- Example: RG1 is in East US.
- The resources inside can be in any region (independent of the RG).
- Example: VM in West Europe, Storage in North Europe, all inside RG1 (East US).

**Why important?**
- Compliance → some companies require metadata to stay in certain regions.
- Disaster Recovery → if RG's region is down, you might have issues managing resources (but resources in other regions can still run).

---

## C. Tagging & Governance (AZ-104)

### Tagging

- You can apply tags (key-value pairs) on a resource group.
- Example: Environment = Production, Department = Finance.
- Purpose: cost tracking, billing, and organization.
- Tags on a resource group do NOT automatically apply to the resources inside.
- To enforce inheritance → use Azure Policy.

### Governance with RBAC

- You can assign roles at the resource group scope.
- Example: Give a user Contributor role on RG1 → they can manage all resources inside RG1.
- Permissions flow downward:
  - RG → resources inside.
  - This helps apply least privilege access at the right level (team/project scope).

**Exam tip:**
Tags = organizational metadata (but not inherited).
RBAC at RG level = access applies to everything inside that group.
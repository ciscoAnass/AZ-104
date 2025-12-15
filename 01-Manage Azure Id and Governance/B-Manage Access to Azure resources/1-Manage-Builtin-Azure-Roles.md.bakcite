# Manage Built-in Azure Roles

## 1. RBAC Basics

**RBAC = Role-Based Access Control**

It controls who can do what on which resources in Azure.

### 3 Main Parts

**Security Principal**
The "who" — user, group, service principal, managed identity

**Role Definition**
The "what" — set of permissions (e.g., read/write/delete)

**Scope**
The "where" — management group, subscription, resource group, or single resource

### How It Works

Access is granted by assigning a role to a principal at a scope.

---

## 2. Built-In vs Custom Roles

### Built-In Roles (Provided by Microsoft)

Ready-made, most common scenarios.

**Examples:**
- **Owner** → full control + delegate access
- **Contributor** → create/manage resources, no access control
- **Reader** → view only
- **User Access Administrator** → manage access (RBAC) only

### Custom Roles (Created by Admins)

Needed if built-in roles don't exactly match your requirements.

You define the permissions JSON (actions allowed/denied).

**Requires:** Azure AD Premium P1 or higher

### Key Points for Exam

- RBAC works at multiple levels of scope (inheritance flows down)
- Built-in roles cover 90%+ of needs; custom roles fill the gaps
- Remember the 4 main built-in roles: Owner, Contributor, Reader, User Access Administrator
- RBAC ≠ Classic Administrator roles (that's legacy)
- RBAC is authorization (what you can do) not authentication (who you are)

---

## 3. Role Structure Basics

A role = collection of permissions (not users). Roles decide what actions a user/service principal/group can do.

### Permission Fields

| Field | Description |
|-------|-------------|
| **Actions** | Allowed management operations (e.g., `Microsoft.Compute/virtualMachines/start/action`) |
| **NotActions** | Exceptions, removes specific permissions from Actions |
| **DataActions** | Access to data inside a resource (e.g., read/write blobs in a storage account) |
| **NotDataActions** | Exceptions for DataActions |

---

## 4. Common Built-In Roles

### Main Roles (Must Know for Exam)

| Role | Permissions |
|------|-------------|
| **Owner** | Full access to resources, can assign roles (delegate access) |
| **Contributor** | Can create and manage resources, but cannot assign roles |
| **Reader** | Read/view resources only, no changes |
| **User Access Administrator** | Manage RBAC role assignments only |

### Service-Specific Roles

Fine-tuned to certain services.

**Examples:**
- **Virtual Machine Contributor** → manage VMs (start/stop/restart), but not access RBAC
- **Storage Blob Data Reader** → read blob/container data, not manage the storage account
- **Billing Reader** → read billing information

### Key Points for Exam

- Always think: **roles = permissions → assigned at scope → applied to principals**
- **Actions vs DataActions:**
  - **Actions** = management plane (control resources)
  - **DataActions** = data plane (access inside resources)
- **Know the 4 main roles** (Owner, Contributor, Reader, User Access Administrator)
- **Service-specific roles** show up often in questions, especially VM Contributor and Storage Blob Data Reader

---

## 5. Least Privilege Principle

Always give users the minimum role needed to perform their job. Don't assign Owner or Contributor if a smaller role fits (e.g., Reader or Storage Blob Data Reader).

This helps reduce security risk and follow best practices.

---

## 6. Data Plane vs Control Plane

### Control Plane

Management of resources (through Azure Resource Manager).

**Example:** Start/stop/create a VM, configure networking

**Roles:** Owner, Contributor, Reader, User Access Administrator

### Data Plane

Access to the data inside a resource.

**Example:** Read/write blobs in a storage account, query a database

**Roles:** Storage Blob Data Reader, Storage Blob Data Contributor, Key Vault Secrets User

### Key Difference

| Aspect | Control Plane | Data Plane |
|--------|---------------|-----------|
| **Definition** | Manage the resource itself | Access contents inside resource |
| **Example** | Create/delete a storage account | Read/write files in the storage account |
| **Common Roles** | Owner, Contributor, Reader | Storage Blob Data Reader, Key Vault Secrets User |

---

## 7. Preview Roles

### What They Mean

Some built-in roles show as **(Preview)**.

This means:
- New service/feature in testing
- Permissions or behavior might change
- For the exam: Just know they exist and can change, but they work like normal roles

### Why Have Preview Roles?

Because the service itself is new or still being tested. Microsoft wants admins to try the role, give feedback, and prepare before GA (General Availability) release.

**Example:**
A new Azure AI service might launch with roles like AI Model Contributor (Preview).

### Key Points for Exam

- **Always apply least privilege** → only what's necessary
- **Understand Control plane vs Data plane clearly** (common test question)
- **Be aware of Preview roles** (don't memorize them all, just know why they exist)
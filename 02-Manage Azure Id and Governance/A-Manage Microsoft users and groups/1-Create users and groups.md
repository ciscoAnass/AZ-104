# Create Users and Groups

## 1. User Creation Basics

### A. Difference Between Cloud-Only Users and Synced Users

**Synced Users**
- Office/local server accounts copied to the cloud
- Sourced from on-premises AD with Azure AD Connect
- Requires Windows Server

**Cloud-Only Users**
- Online accounts that live only in the cloud
- No local server needed
- Managed directly in Azure AD

### B. Default Domain vs Custom Domain

| Aspect | Default Domain (onmicrosoft.com) | Custom Domain (yourcompany.com) |
|--------|----------------------------------|--------------------------------|
| **How You Get It** | Given automatically when you create a Microsoft 365 / Azure tenant | Your real business domain added and verified in Azure/M365 |
| **Example** | yourcompany.onmicrosoft.com | user@yourcompany.com |
| **Appearance** | Looks unprofessional but always exists | Professional for email and login |

**In Short:**
- `onmicrosoft.com` = default, technical, always there
- `yourcompany.com` = custom, professional, what employees actually use

### C. User Properties

| Property | Description |
|----------|-------------|
| **Name (Display Name)** | The full name shown in Teams, Outlook, etc. (e.g., John Smith) |
| **Username / UPN (User Principal Name)** | The user's login and email address (e.g., john@company.com) |
| **Location** | The country/region where the user is based; important for licenses like Microsoft 365 |
| **Roles** | The level of access the user has: User (normal employee) or Admin roles (Global Admin, Exchange Admin, Teams Admin, etc.) |
| **Password Settings** | Controls how users sign in: set/reset password, force password change at next login, or enable Self-Service Password Reset |

**In Short:**
- Name = display label
- UPN = login/email
- Location = license + region
- Roles = permissions level
- Password settings = login security

---

## 2. Group Creation Basics

### A. Types of Groups: Security vs Microsoft 365 Groups

**Security Groups**

Focus only on access and permissions. You group users based on what they are allowed to access, not for collaboration.

Examples:
- **Developers** → access to dev servers, code repository
- **Admins** → access to everything
- **Employees** → access to only basic resources

Think of security groups as "who can open which doors" 🔒

**Microsoft 365 Groups**

Focus only on collaboration and communication. Users in the group can:
- Chat and call in Teams
- Share files in SharePoint
- Manage tasks in Planner
- Use shared email / mailbox

Note: Does not control access to resources like folders or apps.

Example:
- **Project: AI Deep Learning**
  - Members: 2 developers, 1 admin, 4 employees, 3 data scientists
  - They work together using Teams, SharePoint, and Planner

Think of Microsoft 365 groups as "who is working together on this project" 👥💬

### B. Membership Types: Assigned, Dynamic User, Dynamic Device

**1. Assigned**
- You add members manually to the group
- You decide exactly who is in the group
- Example: Group "Admins" with manually added Alice, Bob, and Carol

**2. Dynamic User**
- Membership is automatic based on user properties
- You set rules (like department, country, job title), and Azure AD adds/removes users automatically
- Example: Group "IT Department" with rule "Department = IT" automatically adds any user whose department is IT

**3. Dynamic Device**
- Membership is automatic based on device properties (like OS, compliance, device type)
- Example: Group "Windows 11 Laptops" with rule "DeviceOS = Windows 11" automatically adds any device with Windows 11

### C. Group Settings Summary

| Setting | Description |
|---------|-------------|
| **Mail-Enabled** | If enabled, the group has an email address. Security groups can be mail-enabled (distribution lists). Microsoft 365 groups are always mail-enabled. |
| **Microsoft 365 Collaboration Settings** | Comes with Teams, SharePoint site, Planner, Outlook mailbox. Great for collaboration scenarios (project teams, departments). |
| **Dynamic Group Rules** | Define conditions for auto-membership. Example (user): `user.department -eq "Finance"`. Example (device): `device.deviceOSType -eq "Windows"`. Auto-updates membership as attributes change. |

---

## 3. Group Usage

### A. Using Groups for Role Assignment and Resource Access Control

**1. Role Assignment**

Assign a role to a group, not individual users.

Example:
- **Group:** ExchangeAdmins
- **Role:** Exchange Admin
- **Members:** Alice, Bob → both automatically become Exchange Admins

**2. Resource Access Control**

Use security groups to control access to files, folders, apps, etc.

Example:
- **Folder:** Finance Documents
- **Group:** FinanceTeam
- **Members:** Carol, Dave → all members can access the folder

**Key Idea:**
Groups = buckets of users. Assign roles or resources to the group → everyone inside inherits access automatically.

### B. Best Practices: RBAC Via Groups Instead of Per-User

RBAC (Role-Based Access Control) means assigning permissions based on roles, not individual users.

**Scenario:**
You have a set of tasks where developers need to work on project files but should not touch system/network files.

**Step 1: Create a Role**
- Call it `DevRole`
- Bundle all needed permissions (read/write dev files, no infra access)

**Step 2: Create a Group**
- Call it `ProjectX-Developers`
- Add all devs: Carol, Dave, Eve

**Step 3: Assign the Role to the Group**
- Every member now has DevRole permissions
- No need to assign 17 individual permissions manually

**Step 4: Add New Users**
- Alice joins Project X → add her to ProjectX-Developers
- She automatically gets all DevRole permissions

**Step 5: Reuse Everywhere**
- Next project? Assign DevRole to a new group → same permissions apply

**Big Picture:**
- Role = permission bundle
- Group = container of users
- Assign Role → Group → Users → automatic, reusable, secure

---

## 4. Licensing Considerations

### A. Group-Based Licensing

**What is a License?**

A license defines what services a user can use and includes access to tools and features.

Examples:
- **Email & Calendar** → Exchange Online
- **Teams** → chat, calls, meetings
- **Office Apps** → Word, Excel, PowerPoint
- **OneDrive Storage** → some licenses give 1 TB, others 5 GB
- **SharePoint / Planner / Power Automate / Security features**

Different licenses include different combinations of services and storage.

Example:
- **User A with License X** → can use Email, Calendar, Teams, 5 GB OneDrive
- **User B with License Y** → can use Email, Calendar, Teams, Office apps, 2 TB OneDrive

**What is Group-Based Licensing?**

Instead of giving licenses (like Microsoft 365 E3/E5) to each user individually, you assign the license to a group. Every member of the group automatically receives the license. When a user is removed from the group, the license is automatically removed.

### B. Difference Between Free, P1, and P2 Features

| Tier | Features |
|------|----------|
| **Free** | Basic user & group management, cloud app access, basic security. ❌ Cannot use dynamic groups, advanced security, or self-service group management. |
| **Premium P1** | Includes Free + advanced identity management: ✅ Dynamic groups (auto-add users based on rules), ✅ Self-service group management, ✅ Conditional Access, ✅ Multi-factor authentication policies |
| **Premium P2** | Includes P1 + advanced security & compliance: ✅ Identity Protection (risk-based access), ✅ Privileged Identity Management (PIM), ✅ Access reviews & auditing |

**Example Use Cases:**
- Want a dynamic group of IT users → need P1 or P2
- Want advanced admin monitoring and auditing → need P2

**Pricing of Azure AD Premium**
- **Azure AD Premium P1:** $6 per user/month (annual commitment)
- **Azure AD Premium P2:** $9 per user/month (annual commitment)

---

## 5. Guest Users (B2B Collaboration)

Guest users are external users (people outside your organization) who you invite to collaborate on your resources, like Teams, SharePoint, or other Microsoft 365 apps. They do not need a full company account; they can use their personal or work email to access your resources.

### A. Inviting External Users

**Process:**

1. Go to Azure AD or Microsoft 365 Admin Center
2. Add a Guest User:
   - Enter the external user's email address
   - Optionally, include a personal welcome message
3. Send Invitation:
   - The external user receives an email invitation
   - They click a link to accept the invite
4. Access is Granted:
   - The guest can now access specific resources you allow (Teams, SharePoint, etc.)

**Key Points:**
- Guest users count as users in your Azure AD but usually do not require a paid license unless accessing premium services
- Access is controlled via groups, permissions, or conditional access policies
- Great for collaboration with vendors, partners, or clients without giving them full company accounts

### B. Understanding How Guest Accounts Differ from Members

**1. Member Accounts**
- Internal users of your organization
- Have a full Azure AD identity
- Can access:
  - Microsoft 365 apps (Teams, SharePoint, Exchange)
  - Azure resources (if RBAC roles are assigned)
- Typically used for employees, contractors, or anyone with a company account
- Can be added to any group, assigned roles, and use all features your license allows

**2. Guest Accounts**
- External users (people outside your organization)
- Limited Azure AD identity
- By default, can access:
  - Microsoft 365 collaboration apps (Teams, SharePoint, OneDrive)
  - Azure resources only if you explicitly assign RBAC roles
- Cannot be a full "member" of your directory—some features are restricted
- Often used for vendors, partners, or external collaborators

**In Summary:**
- Member = full employee account
- Guest = invited collaborator with limited access
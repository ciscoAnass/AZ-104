# Manage User Properties

## 1. User Properties

### A. Profile Attributes

**Profile Information**

| Attribute | Description |
|-----------|-------------|
| **Name** | Display name shown across Microsoft 365 (Teams, Outlook) |
| **Username/UPN** | Unique login ID (user@domain.com) |
| **Job Title** | Describes role (e.g., IT Admin) |
| **Department** | Groups users by function (e.g., HR, Finance) |
| **Office Location** | Physical office info |
| **Usage Location** | Country/region of service use; required for license assignment |

**Contact Information**

| Attribute | Description |
|-----------|-------------|
| **Email** | Secondary (not UPN), used for recovery/notifications |
| **Phone** | Mobile/office numbers, also used for MFA & SSPR |
| **Address** | Street, city, state, country, zip; more for HR/compliance |

**Key Points:**
- UPN = sign-in identity
- Usage Location must be set before assigning licenses
- Contact info helps with security (MFA, SSPR)

### B. Account Settings

**Password Reset Requirements**

You can set whether a user must change their password at next sign-in (common for new accounts or reset accounts). Admins can also manually reset a user's password in the portal/PowerShell/CLI.

Identity verification uses authentication methods:
- Phone call
- SMS code
- Email
- Microsoft Authenticator app
- Security questions

If Self-Service Password Reset (SSPR) is enabled, users can reset their password themselves after verifying their identity.

**Exam Tip** ⚡
Remember that admins can force "must change password at next sign-in."

**Block/Unblock Sign-in**

| Action | Effect |
|--------|--------|
| **Block Sign-in** | Disables the user's ability to log in to Azure, Microsoft 365, Teams, etc. Useful if someone leaves the company or if their account is compromised. |
| **Unblock Sign-in** | Re-enables access when the issue is resolved. |

**Important Note:** "Block sign-in" does not remove the license, group memberships, or data — it only prevents logon. This is a quick security action, different from deleting the account.

**Exam Tip** ⚡
"Block sign-in" is a non-destructive way to prevent access while preserving all user data and settings.

**Assigning Roles**

Every Entra ID user has a role that defines what they can do.

- **Default Role:** User (standard permissions, can access apps but cannot manage directory)

**Common Roles:**

| Role | Permissions |
|------|-------------|
| **Global Administrator** | Full control over the tenant (highest privilege, can manage everything) |
| **User Administrator** | Can manage users and groups but not high-privilege roles |
| **Billing Administrator** | Manages billing, purchases, invoices |
| **Global Reader** | Read-only access to all admin features (useful for auditors) |
| **Service-Specific Roles** | Security Admin, Intune Admin, Teams Admin, Exchange Admin, etc. |
| **Custom Roles** | Create custom roles with specific permissions |

**Exam Tip** ⚡
Follow the least privilege principle → don't give Global Admin unless truly required.

---

## 2. Directory Role Assignment Best Practices

### 1. Least Privilege Principle

**Definition**
Always give users only the minimum permissions needed to do their job.

**Why**
Reduces risk if an account is compromised.

**How to Apply in Entra ID**

- Don't give Global Administrator unless absolutely necessary
- Instead, assign service-specific roles (e.g., Teams Admin, Exchange Admin, Billing Admin)
- Use custom roles if built-in ones don't match exactly

**Exam Tip**
If you see "assign Global Admin" vs. "assign User Admin" → the correct answer is usually the smaller role.

### 2. Privileged Identity Management (PIM)

**Overview**

PIM is part of Microsoft Entra ID P2 (premium license).

**Purpose**
Manage, monitor, and control access to privileged roles.

**Key Features**

| Feature | Description |
|---------|-------------|
| **Just-in-Time Role Activation** | Users get admin rights only when they need them, for a limited time |
| **Approval Workflow** | Role activation can require manager or security officer approval |
| **MFA Enforcement** | Extra security before granting elevated privileges |
| **Auditing & Alerts** | Track who activates roles, when, and for how long |

**Exam Context**
Even though it's a P2 feature, AZ-104 wants you to know what it is and why it's safer than permanent role assignments.
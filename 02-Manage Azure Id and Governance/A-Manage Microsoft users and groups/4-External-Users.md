# External Users

## 1. External Users Overview

### A. Member vs Guest

**Member**
- Full internal user (your company's employees)
- Example: an employee with a company email like user@contoso.com
- Has full access depending on their role/license

**Guest**
- External collaborator (partners, contractors, consultants, Gmail/Outlook users, etc.)
- Example: someone with gmail.com or yahoo.com invited into your tenant
- Limited permissions by default (not full internal rights)

**Exam Tip:**
Guests are "external" but can still be put into groups and given access to resources.

### B. Identifiers

A Guest account UPN looks different.

**Format:**
`username_gmail.com#EXT#@tenant.onmicrosoft.com`

This helps you know it's an external user.

### C. Licensing Rules

**By Default:**
Guests don't consume a license.

**However:**
If you want them to use premium features (like Teams, Office apps, Intune, etc.), you must assign a license.

**Key Point:**
Members always need licenses. Guests only need licenses if you assign one.

### What to Remember for the Exam

- **Member** = employee, needs license
- **Guest** = external, UPN with #EXT#, no license by default
- **Guests can still join groups**, access apps, collaborate
- **If a Guest needs premium features** → assign license manually

---

## 2. Invitation Process

### A. How to Invite

**Path:**
Azure Portal → Microsoft Entra ID → Users → New guest user

**Options to Invite:**
- Enter email address of the guest
- Send a redeemable invitation link

### B. Redemption (When Guest Accepts)

Guest gets an email invite. They accept → log in with their own identity:
- **Microsoft account** (Outlook, Hotmail)
- **Another Entra ID tenant** (work account)
- **Even Gmail/Yahoo** (converted into a Microsoft identity)

### C. Self-Service Sign-Up (If Enabled)

Instead of you inviting, guests can request access themselves.

Example: external partners sign up via a link or app portal.

### What to Remember for Exam

- **Admin can invite** via Entra → Users → New guest user
- **Guests redeem invitation** using their own identity
- **Self-service sign-up** = external users initiate request

---

## 3. Access & Permissions

### A. Groups

Guests can be added to:
- **Security groups** (for access control to apps, files, resources)
- **Microsoft 365 groups** (for collaboration in Teams, SharePoint, Planner, Outlook)

Example: Add a contractor as a guest in the Marketing Team's M365 group so they can join Teams chats and SharePoint.

### B. Applications

You can assign guests to Enterprise Applications (under Entra ID → Enterprise apps → Assign users/groups). This gives them access to SaaS apps (like Salesforce, ServiceNow, custom apps). Common for B2B collaboration where external partners need app access.

**Enterprise Applications:**
All the external/internal apps connected to your company's identity system. Can also be third-party apps (Amazon, Google Cloud, Dropbox, Cisco, Zoom, etc.). Companies often use many tools, not just Microsoft.

### C. Roles

Technically, you can give guests directory roles (like Global Admin, User Admin, etc.).

**Not Recommended:**
Breaks the least privilege principle (only give minimal access needed).

**Best Practice:**
Avoid giving guests high-level roles unless absolutely required.

### D. Controls

**Conditional Access**

Use Conditional Access to secure guest access:
- Require MFA for guests
- Restrict access by location or device compliance

Examples:
- Require MFA if logging in from outside your corporate network
- Block access if the device is not compliant
- Allow access only from specific locations/IP

**Access Reviews** *(P2 feature, but exam relevant)*

Regularly check if guests still need access:
- Owners/managers review guest memberships
- Helps prevent stale accounts (e.g., contractor left 6 months ago but still has access)

Process:
- Owners/managers get a review task: "Does this guest still need access? Yes/No."
- If no → access is removed automatically

### What to Remember for Exam

- **Guests can join groups and apps** like members
- **Guests shouldn't be given high-level roles** (least privilege)
- **Use Conditional Access** for policies (e.g., MFA)
- **Use Access Reviews** to clean up unused guest accounts

---

## 4. Security & Governance

### A. Access Restrictions

In Entra ID, you can configure "Guest access" settings at the tenant level.

**Examples:**
- Limit what guests can see/do
- Stop them from enumerating users (they shouldn't be able to list all company users)

**Important:**
Teams and SharePoint have their own "External sharing" settings → must configure separately.

### B. Access Reviews

Over time, many guests may stay in your tenant (old partners, contractors). To avoid keeping unused accounts, you use Access Reviews.

**Process:**
An owner or admin gets a reminder every few months to check: "Does this guest still need access? Yes or No?"

If the answer is No → the guest is automatically removed.

This keeps the environment clean and secure.

### C. Terms of Use & MFA

**Terms of Use:**
You can show guests a Terms of Use document (rules or contract) that they must accept before getting access.

**Multi-Factor Authentication:**
You can also force guests to use MFA (Multi-Factor Authentication) with Conditional Access.

Example: guest must enter a code from their phone, even if they log in with Gmail. This makes guest accounts more secure.

### What to Remember for AZ-104

- **Guest access restrictions** at tenant level (limit permissions, block enumeration)
- **Teams/SharePoint external sharing** must be managed separately
- **Access reviews** = regular cleanup of guest access
- **Terms of Use + MFA** can be required for guests
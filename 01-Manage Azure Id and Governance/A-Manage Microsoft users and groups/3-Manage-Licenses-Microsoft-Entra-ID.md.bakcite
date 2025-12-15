# Manage Licenses in Microsoft Entra ID

## 1. License Basics

### A. What is a License?

In Microsoft Entra ID (formerly Azure AD) and Microsoft 365, a license is what activates cloud services for a user.

**Without a License:**
- User can log in, but can't use core apps/services

**With a License:**
The account gains access to workloads like:
- **Exchange Online** → mailbox, email, calendar
- **Teams** → chat, meetings, collaboration
- **SharePoint Online / OneDrive** → document storage & collaboration
- **Intune (Endpoint Manager)** → device/app management
- **Office desktop apps** (Word, Excel, PowerPoint) – if included in the plan

**Key Concept:**
Think of the license as a subscription ticket that defines what a user is allowed to do.

### B. Types of Licenses

**Base Licenses (Core Packages)**

These are all-in-one bundles that include the main Microsoft 365 services.

Examples:
- Microsoft 365 E3 / E5
- Office 365 E1 / E3 / E5

They provide:
- Office apps (web/desktop, depending on plan)
- Teams, Exchange Online, SharePoint, OneDrive
- Security/compliance features (depending on tier)

Every user who needs Microsoft 365 apps and services needs at least one base license.

**Add-On Licenses (Optional Extras)**

These are special-purpose licenses you assign in addition to a base license.

Examples:
- **EMS (Enterprise Mobility + Security)** → adds advanced identity & device protection
- **Power BI Pro** → enables advanced analytics & dashboards
- **Teams Phone System** → calling features

They don't replace base licenses; instead, they extend capabilities.

**Analogy:**
- Base license = the core smartphone plan (calls, SMS, internet)
- Add-on license = extra services (international roaming, Netflix, 5G booster)

### C. Usage Location Requirement

**Why Required?**
Because not all Microsoft services are available everywhere.

For example:
- Teams phone system might not be legal/available in some countries
- Compliance features differ across regions

**Rule:**
You must set the "Usage location" property on the user account before assigning a license. If no usage location is set → license assignment will fail.

**Common Exam Scenario:**
If a user can't get a license → check if usage location is missing or incorrect.

### Exam-Oriented Key Points to Remember

- **License** = unlocks Microsoft 365/Entra services (Exchange, Teams, SharePoint, Intune, etc.)
- **Base license** = core package (E3/E5, Office 365)
- **Add-on license** = extra features (EMS, Power BI Pro, Teams Phone)
- **Usage location** must be set → otherwise license assignment won't work
- **One user can have multiple licenses**, but they need at least one base license to be functional
- **Licensing is managed** in Microsoft Entra admin center or Microsoft 365 admin center

---

## 2. License Assignment Methods

### A. Per-User Assignment

The most basic method where you (the admin) manually assign a license to each user account.

**Path:**
Microsoft Entra admin center → Users → Licenses → Assignments

**Pros and Cons:**
- ✅ Works fine for small environments
- ❌ Doesn't scale well (harder if you have hundreds of users)

### B. Group-Based Licensing *(Requires Entra ID P1 or Higher)*

Instead of assigning licenses one by one, you assign them to a group. All members automatically inherit that license.

**Benefits:**
- Easy to manage at scale
- Dynamic groups = even more powerful → licenses auto-apply based on rules (e.g., "all users in Department=HR")
- If a user leaves the group → the license is automatically revoked
- If a new user joins the group → they automatically get the license

**Exam Tip:**
Group-based licensing = only available if you have Azure AD Premium P1/P2

### C. Assigned vs Inherited Licenses in the Portal

**Assigned License (Direct)**

You manually attach a license to a user.

Example:
- Open User → Licenses → Assignments → +Add license and pick Microsoft 365 E3
- That license now shows as Assigned
- It sticks with the user even if they leave groups

Think of it like: you hand the key directly to the person.

**Inherited License (From Group)**

The license comes because the user is in a group that has a license.

Example:
- The group "HR Team" has the Microsoft 365 E3 license assigned
- All members of that group automatically get that license
- If a user leaves the group, they lose the license
- In the portal it shows as Inherited (you'll see "Source: Group licensing")

Think of it like: you join a club, and the club gives you a key. If you leave the club, the key is taken back.

---

## 3. Service Plans

### A. What is a Service Plan?

A license (like Microsoft 365 E3) is made up of multiple individual service plans. Each service plan corresponds to a specific app or feature.

**Example: M365 E3 License Includes Service Plans Like:**
- **Exchange Online (Plan 2)** → email & calendar
- **Teams** → collaboration & meetings
- **SharePoint Online (Plan 2)** → intranet, file storage
- **OneDrive for Business (Plan 2)** → personal cloud storage
- **Intune (Endpoint Manager)** → device management
- **Office Apps for Enterprise** → Word, Excel, PowerPoint desktop apps

So, when you assign E3, you're really giving a bundle of service plans.

### B. Enabling / Disabling Service Plans

As an admin, you don't always need to give all features of a license to a user. You can toggle individual service plans ON or OFF.

**Examples:**
- A contractor only needs Teams, but not Exchange mailbox → disable Exchange Online plan for them
- An employee only uses Outlook email and OneDrive → disable Teams and Intune

This way, you fine-tune what parts of the license each user actually gets.

### C. How It Looks in the Portal

**Path:**
User → Licenses → [License name] → Apps

You'll see a list of all service plans inside that license. You can check/uncheck them per user. With group-based licensing → you can also configure service plan settings at the group level.

### Example Scenario (Exam-Style)

You assign M365 E3 to an employee. By default, they get: Exchange, Teams, SharePoint, OneDrive, Intune, etc.

**HR says:** "This employee doesn't need Teams."

**Solution:** Go into their license settings → uncheck Teams service plan.

**Result:** They still have E3, but Teams is disabled for them.

### Exam Takeaways

- **License** = bundle of service plans
- **Service plan** = individual app/feature (Exchange, Teams, OneDrive, Intune, etc.)
- **You can enable/disable service plans** per user or group
- **Useful for** compliance, cost control, and customization
- **Shows up in portal** as checkboxes under a license

---

## 4. Monitoring & Troubleshooting License Assignments

### A. Check License Availability

Microsoft 365 / Entra licenses are like seats you buy. If your company bought 100 E3 licenses and already assigned 100 → you can't assign #101.

**Check Here:**
Microsoft 365 admin center → Billing → Licenses to see how many are:
- Purchased
- Assigned
- Available

**PowerShell Check (MSOnline Module):**
```powershell
Get-MsolAccountSku
```

### B. License Conflicts (Merging)

If a user gets licenses from multiple groups, Microsoft merges them into one effective set of features.

**Example:**
- Group A gives E3
- Group B gives EMS E5
- Result → the user has E3 + EMS E5 features together

If both groups give the same license (e.g., E3 twice), the system avoids double-billing → user only consumes 1 seat.

**Exam Tip:**
Licenses merge, not override.

### C. Common Errors & Fixes

**No Usage Location Set**

- **Error:** License assignment fails with no usage location
- **Fix:** Go to user properties → set usage location → re-assign license

**Insufficient Available Licenses**

- **Error:** "Not enough licenses available"
- **Fix:** Buy more seats or remove license from another user

**Conflicts Between Service Plans**

- **Error:** Some service plans can't coexist (example: two different versions of Exchange Online in different bundles)
- **Fix:** Edit the license → uncheck the conflicting service plan

**Disabled Account**

- **Error:** "The user is blocked from sign-in" or "User not found"
- **Cause:** You cannot assign licenses to a blocked or deleted user
- **Fix:** Re-enable the account or restore it before assigning licenses
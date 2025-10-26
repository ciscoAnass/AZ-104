# Configure Self-Service Password Reset (SSPR)

## 1. SSPR Basics

### What It Is

Lets users reset their own password without calling IT/helpdesk.

### Why It Matters

- Saves time for users
- Reduces helpdesk workload
- Improves productivity

### How It Works

1. Admin enables SSPR in Microsoft Entra ID
2. Users must register authentication methods (like phone number, email, Authenticator app, security questions)
3. If they forget their password → go to the reset portal (`https://aka.ms/sspr`)
4. They verify their identity using the registered methods → set a new password

### Key Settings

- You can choose how many methods are required (1 or 2)
- You can scope SSPR to all users or just specific groups
- You can integrate with on-premises Active Directory if hybrid

### Exam Tip

Remember:
- Users reset own passwords
- Needs registration of methods first
- Reduces helpdesk calls
- Admins configure it (who can use it + how many methods)
- Reset portal: `https://aka.ms/sspr`

---

## 2. Authentication Methods for SSPR

### What It Is

Ways users prove their identity before resetting their password.

### Examples of Methods

- 📱 **Phone** (call or SMS)
- 📧 **Email** (not work email, but alternate personal email)
- 🔒 **Microsoft Authenticator app** (notification or code)
- ❓ **Security questions** (less recommended, but still an option)

### Registration

Users must register their methods ahead of time via the portal: `https://aka.ms/setupsecurityinfo`

Without registration, they cannot reset their password.

### Admin Control

Admin decides which methods are available. Admin sets how many methods must be verified:
- **1 method** → simple, easier, less secure
- **2 methods** → stronger, recommended

### Exam Tip

- Know that admins configure the policy (methods + number required)
- Users must register first, otherwise SSPR won't work
- Portal for reset: `https://aka.ms/sspr`
- Portal for register: `https://aka.ms/setupsecurityinfo`

---

## 3. SSPR Scope (Who Can Use It)

### None

SSPR is disabled. Nobody can use it.

### Selected Groups

Only chosen users (like a pilot/test group) can use SSPR.

👉 **Best practice:** Test with a small group before rolling out.

### All Users

Every user in the tenant can use SSPR.

👉 **Full deployment** once tested.

### Exam Tip

- **Scope** = who gets SSPR
- **Typical rollout:** Pilot (selected group) → then All users
- **If scope = None** → SSPR doesn't work at all

---

## 4. SSPR Registration

### Where Users Register

👉 `https://aka.ms/ssprsetup` (or `https://aka.ms/setupsecurityinfo`)

### What They Do

Users provide their authentication methods (phone, email, Authenticator app, etc.).

### Admin Options

Can enforce registration at sign-in → users are forced to set up security info before they can continue.

Ensures everyone has methods ready when they forget password.

### Exam Tips

- **Without registration** → users cannot use SSPR
- **Enforce registration** = best practice (so all users are covered)

### URLs to Memorize

| Purpose | URL |
|---------|-----|
| **Registration** | `https://aka.ms/ssprsetup` |
| **Reset Password** | `https://aka.ms/sspr` |

---

## 5. SSPR Reset Process

### Step 1: User Forgets Password

User goes to reset portal: `https://passwordreset.microsoftonline.com`

### Step 2: Verify Identity

User must pass the checks with their registered authentication methods (phone, email, Authenticator app, etc.).

Number of methods required depends on admin policy (1 or 2).

### Step 3: Set New Password

Once verified, user creates a new password that meets the organization's password policy.

### Step 4: Sign In Again

User logs back in with the new password.

### Exam Tips

- **Reset portal** = `https://passwordreset.microsoftonline.com`
- **Verification** uses pre-registered methods only
- **Password** must respect org/tenant password rules
- **If hybrid with on-prem AD** → requires Password Writeback to update both cloud & on-prem

---

## 6. SSPR Licensing

### Microsoft Entra ID Free

- Basic SSPR
- Works only for cloud-only accounts (no on-premises AD)
- Good for small cloud-only orgs

### Microsoft Entra ID P1 / P2

Advanced SSPR features, including:
- **Password writeback** → if user resets in cloud, it also updates on-prem Active Directory
- **Hybrid scenarios** (cloud + on-prem)
- **Enterprise-scale controls**

### Exam Tips

- **Free** → basic, cloud-only
- **P1/P2** → advanced, hybrid integration + writeback
- **Remember:** Password Writeback = needs P1/P2

---

## 7. Password Writeback

### What It Is

When a user resets their password in Entra ID (Azure AD) using SSPR, the new password also updates in on-prem Active Directory.

### Requirements

- **Microsoft Entra Connect** (sync tool)
- **Entra ID P1/P2 license** (not available in Free)

### Why It Matters

**Without writeback:**
- Only cloud password changes
- On-prem AD users stay locked out

**With writeback:**
- One reset updates both cloud & on-prem
- Seamless experience

### Exam Tips

- **Keyword: Hybrid** = needs password writeback
- **Needs** P1/P2 license + Entra Connect
- **Cloud-only accounts** → no need for writeback

---

## Best Practices

- Require at least 2 authentication methods for stronger security
- Monitor password reset activity in Azure AD audit logs
- Combine with MFA registration (streamlined user experience)
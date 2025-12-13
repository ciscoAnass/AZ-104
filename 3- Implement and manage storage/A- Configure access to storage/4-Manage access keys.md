# Manage Access Keys for Azure Storage Accounts

## A. What are storage account access keys?

Every Storage account has **two access keys**:

- **key1**  
- **key2**

These are long secrets that:

- Grant **full data-plane access** to all services in the account (Blob, Files, Queues, Tables) depending on the account type.  
- Are used to sign **SAS tokens** and generate **connection strings**. citeturn0search3turn0search1

Because they grant such broad access, they are extremely sensitive and must be protected like passwords or root secrets.

> **Important:** Access keys are **not identity-based**. If someone has the key, they can act as the storage account, regardless of their Entra identity or RBAC access.

---

## B. When to use keys vs alternatives

### Keys – pros & cons

**Pros**

- Simple: single secret works for all services.  
- Required to sign **Account SAS** and some advanced operations.

**Cons**

- Very powerful (too much privilege).  
- Hard to rotate if you spread the key across many apps.  
- No per-user traceability – all access looks like “storage account access.”

### Preferred alternatives

Microsoft recommends: citeturn0search3turn0search1turn0search21

- Use **Microsoft Entra ID** + **RBAC** where supported (especially for blob and Azure Files scenarios).  
- Use **user delegation SAS** when you need delegated blob access tied to identities. citeturn0search6turn0search11turn0search16  
- Use **service principals / managed identities** + Azure AD auth instead of embedding keys in code.

> **Exam tip:** If a scenario is about **improving security**, the answer is usually “move away from using account keys directly” toward SAS or Entra-based auth.

---

## C. Where keys are used

Common usage patterns: citeturn0search3

- **Connection strings** (`DefaultEndpointsProtocol`, `AccountName`, `AccountKey`, `EndpointSuffix`).  
- **Legacy applications** that don’t support Entra auth.  
- **Signing SAS tokens** (service or account SAS) when you don’t use user delegation SAS.  
- Integration with services that expect a Storage connection string (some older SDKs, tools).

You should **minimize** the number of systems and apps that rely directly on these keys.

---

## D. Key rotation – why and how often

### Why rotate keys?

- If a key leaks and you never rotate it, that leak is permanent.  
- Regular rotation reduces the window where a compromised key remains valid.

Microsoft guidance: rotate keys **regularly** (for example, every 90 days) and use tools like **Azure Key Vault** to manage rotation. citeturn0search3turn0search29turn0search22

### How two keys enable safe rotation

The Storage account gives you **two keys** so that you can:

1. Use **key1** in your apps.  
2. When it’s time to rotate:
   - Update your apps to use **key2**.  
   - Regenerate **key1**.  
3. Later, switch back:
   - Update apps to use the newly regenerated **key1**.  
   - Regenerate **key2**.

This **ping-pong** pattern lets you rotate without downtime. citeturn0search3turn0search18turn0search26

> **Best practice:** At any time, try to have **only one key actively used** by your applications. If you mix both keys across apps, rotation becomes risky and complex. citeturn0search18

---

## E. Using Azure Key Vault for key management

Microsoft strongly recommends storing and rotating Storage account keys via **Azure Key Vault**: citeturn0search3turn0search8turn0search13

- Store the keys in Key Vault as **secrets**.  
- Your applications retrieve keys securely using managed identity / service principal.  
- You can configure **automatic rotation** in Key Vault for secrets representing Storage account keys.

Example pattern:

1. In Key Vault, configure a **rotation policy** for the secret holding `key1`. citeturn0search8turn0search13turn0search22  
2. Create an automation (Functions, Logic Apps) that:
   - Regenerates the Storage account key.  
   - Updates the secret in Key Vault.  
3. Apps always grab the latest key from Key Vault using managed identity.

This keeps keys **out of code** and eliminates manual distribution.

---

## F. Viewing and regenerating keys in the portal

### Viewing keys

1. Go to **Storage account → Settings → Access keys**. citeturn0search3  
2. You see **key1** and **key2** plus connection strings.  
3. Use the **Show** button to reveal them (if you have required permissions).

### Regenerating keys

On the same blade:

1. Choose **Regenerate key1** or **Regenerate key2**. citeturn0search3  
2. Confirm – the old key value becomes invalid almost immediately.  
3. Update any apps using that key with the new value (preferably via Key Vault).

Permissions:

- To view or regenerate keys, users typically need roles like **Storage Account Key Operator Service Role** or higher, depending on scenario. citeturn0search3

---

## G. CLI / PowerShell examples (conceptual)

### Azure CLI – list keys

```bash
az storage account keys list \
  --resource-group myrg \
  --account-name mystorageaccount
```

### Azure CLI – regenerate a key

```bash
az storage account keys renew \
  --resource-group myrg \
  --account-name mystorageaccount \
  --key primary
```

Or `--key secondary` to rotate key2. citeturn0search3turn0search26

PowerShell equivalents use cmdlets like `Get-AzStorageAccountKey` and `New-AzStorageAccountKey`.

You do **not** need exact syntax for the exam, but be able to interpret what such commands accomplish.

---

## H. Access keys vs SAS vs Entra auth

| Aspect | Access keys | SAS | Entra ID / RBAC |
|--------|------------|-----|------------------|
| Scope | Entire account (data plane) | Scoped to resource(s) | Scoped to identity & resource |
| Time-bound | No (until rotated) | Yes (expiry) | Token lifetime + policies |
| Granularity | Very coarse | Fine (permissions, resource) | Fine (roles, ACLs) |
| Revocation | Rotate keys | Expire or revoke SAS (policy) | Disable account / change roles |
| Recommended use | Legacy or special cases | Client delegation | Modern apps & users |

> **Exam mindset:**  
> - **Security first**: prefer Entra-based auth over keys.  
> - Use SAS when you need client delegation, especially from browsers/mobile.  
> - Use keys only where necessary and always plan a **rotation strategy**.

---

## I. Scenario-based examples

### Scenario 1 – Secure legacy app still using keys

> “A legacy line-of-business app uses a connection string with the storage account key. How can you improve security without rewriting the app?”

- Move the key to **Azure Key Vault**. citeturn0search3turn0search8  
- Configure the app to retrieve the connection string from Key Vault via a managed identity.  
- Implement **key rotation** (automated or manual).

### Scenario 2 – Keys leaked on GitHub

> “A developer accidentally committed a storage account key to a public GitHub repo.”

Steps:

1. **Regenerate** the exposed key immediately (e.g., key1). citeturn0search3  
2. Update any apps that used key1 to use key2 (or the newly regenerated key via Key Vault).  
3. Review logs and **rotate SAS** or policies if they may have been compromised.

### Scenario 3 – Need to invalidate many SAS tokens

> “You issued SAS tokens signed with key1. Now you suspect they are compromised and some consumers don’t use stored access policies.”

- Regenerate **key1** to invalidate those SAS tokens. citeturn0search3turn0search1  
- For future SAS that must be revocable, use **stored access policies** so you can revoke them more easily.

### Scenario 4 – Compliance requires key rotation every 60 days

> “Policy states all secrets must be rotated every 60 days, including storage account keys.”

- Use **Key Vault** rotation policies + a function or automation to regenerate keys on schedule. citeturn0search8turn0search13turn0search22  
- Ensure apps always fetch keys from Key Vault and don’t hardcode them.

---

## J. Exam takeaways

- Storage accounts have **two keys** which grant broad data-plane access. citeturn0search3  
- Keys should be **protected**, **rotated**, and ideally **stored in Key Vault**. citeturn0search3turn0search8turn0search13  
- Use the **two-key ping-pong pattern** for rotation with minimal downtime. citeturn0search18turn0search26  
- Prefer **Entra-based auth** and **SAS** over direct key usage whenever possible. citeturn0search1turn0search6turn0search11turn0search21  
- If keys are compromised, **regenerate them immediately**, and understand this also invalidates SAS signed with that key.

Mastering access keys is not about memorizing commands; it’s about designing a secure, maintainable strategy for secret management and rotation.
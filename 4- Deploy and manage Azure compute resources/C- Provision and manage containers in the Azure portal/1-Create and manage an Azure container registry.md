# Create and manage an Azure Container Registry (ACR)

## 1. Concept overview

### What is ACR?

Azure Container Registry (ACR) is a **managed, private container registry** in Azure.  
You use it to **store and manage container images and other OCI artifacts**, similar to Docker Hub, but inside your own Azure subscription.

A typical flow:

1. Developer builds a container image.
2. Image is **pushed** to ACR.
3. Azure services like **Azure Container Instances, Azure Container Apps, AKS, App Service** **pull** the image from ACR and run it.

```text
[Dev machine / CI pipeline]
           |
      docker push
           v
   +----------------------+
   |  Azure Container     |
   |      Registry        |
   +----------------------+
       ^            ^
       |            |
    docker pull   Azure services (ACI, ACA, AKS…)
```

### Key ACR concepts

| Term        | Meaning                                                                 |
|------------|-------------------------------------------------------------------------|
| Registry   | The overall ACR resource. One per Azure resource.                       |
| Repository | A named collection of images (for example `myapp/backend`).             |
| Image      | Packaged application. Identified by a tag (`myapp/backend:1.0.0`).      |
| Tag        | Human‑readable label for a specific image version (`:latest`, `:prod`). |
| Artifact   | Any OCI artifact: images, Helm charts, SBOMs, etc.                      |

**Exam angle:**  
Know the difference between **registry** (top‑level resource) and **repository** (logical group of images inside a registry).

---

## 2. ACR SKUs and features

ACR has three main SKUs:

| SKU      | Typical use                          | Key points (high level)                                   |
|----------|--------------------------------------|-----------------------------------------------------------|
| Basic    | Dev / test                           | Lower throughput, cheapest.                              |
| Standard | Most production workloads            | More storage/throughput than Basic.                      |
| Premium  | Large / globally distributed systems | Adds **geo‑replication**, content trust, more throughput.|

Important feature to remember:

- **Geo‑replication (Premium only):**
  - Replicates your registry to multiple Azure regions.
  - Images are pushed once, then pulled locally from each replica.
  - Reduces latency for global deployments and increases resilience.

---

## 3. Creating an Azure Container Registry (portal)

Steps in the **Azure portal**:

1. **Search** for **“Container registries”** → **Create**.
2. **Basics tab**
   - Subscription: choose the exam’s subscription.
   - Resource group: existing or new.
   - Registry name: must be **globally unique**, lowercase, no spaces (for example `mycompanyacr`).
   - Location: choose region close to your workloads.
   - SKU: Basic / Standard / Premium.
3. **Encryption**
   - By default ACR uses **Microsoft‑managed keys**.
   - For extra compliance, you can use a **customer‑managed key** in Azure Key Vault.
4. **Networking**
   - Default: **public endpoint (all networks)**.
   - For production: often **disable public network** and enable **private endpoints** or IP firewall rules.
5. **Review + create** → wait for deployment.

After deployment, registry login server looks like:

```text
<registry-name>.azurecr.io
```

---

## 4. Authentication and authorization

You must **authenticate** before pushing or pulling images.

### 4.1 Authentication options

1. **Azure AD identities (recommended)**
   - Users, service principals, or **managed identities**.
   - Use RBAC roles like **AcrPull**, **AcrPush**, **AcrDelete**.
   - Secure and auditable.

2. **Admin user (legacy / simple labs)**
   - Per‑registry username/password.
   - Disabled by default, can be enabled in **Access keys** blade.
   - Convenient for demos, **not recommended** for production.

3. **Access keys / tokens**
   - Some scripts use `az acr login` which obtains a token using your Azure AD credentials.

**Exam tip:**

- If question says _“meet security best practices, avoid shared passwords”_ → use **Azure AD** + **AcrPull/AcrPush** roles, not the admin account.

### 4.2 Common RBAC roles

| Role     | What it lets you do                                           |
|---------|----------------------------------------------------------------|
| AcrPull | Pull images and artifacts only.                                |
| AcrPush | Pull + push images (but not change registry settings).        |
| AcrDelete | Delete images and artifacts.                                 |
| Owner / Contributor | Full management of registry resource itself.      |

Assign roles at registry, resource group, or subscription scope.

---

## 5. Pushing and pulling images

### 5.1 Login to registry

From a dev machine with Docker and Azure CLI:

```bash
# Azure CLI login
az login

# Option 1 – convenience (uses your Azure AD identity)
az acr login --name mycompanyacr

# Option 2 – classic Docker login (if ACR admin user is enabled)
docker login mycompanyacr.azurecr.io
```

### 5.2 Tag and push an image

1. Build a local image:

```bash
docker build -t myapp:v1 .
```

2. Tag it with the ACR login server:

```bash
docker tag myapp:v1 mycompanyacr.azurecr.io/myapp/backend:v1
```

3. Push to ACR:

```bash
docker push mycompanyacr.azurecr.io/myapp/backend:v1
```

Now the image lives inside repository `myapp/backend` in your ACR.

### 5.3 Pull an image

From any authorized client (ACI, Container Apps, AKS, or local Docker):

```bash
docker pull mycompanyacr.azurecr.io/myapp/backend:v1
```

Other Azure services usually pull images automatically when you specify the **image name** and **registry**; they use managed identities or service principals to authenticate.

---

## 6. ACR networking and security

### 6.1 Public access with firewall rules

- Public endpoint is available on the internet.
- You can:
  - Allow access from **all networks** (default).
  - Or limit to specific **IP ranges** and **virtual networks**.

Exam scenario:  
If requirement is _"only allow images to be pulled from on‑premises IP ranges"_, configure **public endpoint** with **IP firewall rules**.

### 6.2 Private endpoints

For higher security you can:

- Disable public network access.
- Create **private endpoints** in chosen VNets.
- ACR is then reachable only via **private IPs** inside those VNets.

This is common when AKS, Container Apps, or ACI run inside private subnets.

### 6.3 Encryption and image scanning

- All data is encrypted at rest using Azure Storage encryption.
- Optional: use **customer‑managed keys** from Key Vault.
- For security posture, organizations often pair ACR with vulnerability scanning (for example Microsoft Defender for Cloud).

---

## 7. ACR Tasks and automation (important concept)

**ACR Tasks** let you build and maintain container images directly in Azure, without a local build agent.

Typical uses:

- Build new images when code is pushed to GitHub/Azure Repos.
- Automatically rebuild image when a **base image** is updated.
- Run scheduled builds (nightly, weekly).
- Run a one‑time task in a container (for example data migration).

Simple example CLI (for understanding, not required to memorize):

```bash
az acr task create   --registry mycompanyacr   --name build-webapp   --image webapp:{{.Run.ID}}   --context https://github.com/myorg/webapp.git   --file Dockerfile   --git-access-token <token>
```

**Exam angle:**  
If you see **“build images in Azure automatically when code changes”**, think **ACR Tasks** (not ACI/Container Apps).

---

## 8. Retention, cleanup, and image lifecycle

Over time registries can fill with old images. ACR provides:

### 8.1 Retention policies for untagged manifests

- You can configure a **retention policy** to automatically delete **untagged image manifests** after N days.
- Helps control storage and keep the registry clean.

### 8.2 Other cleanup strategies (conceptual)

- Use **tags** for stages: `:dev`, `:test`, `:prod`.
- Regularly delete old tags or repositories with scripts.
- Lock important images you must keep.

**Exam tip:**  
If the question mentions **“remove old images automatically”**, look for **ACR retention policy**, not manual deletion.

---

## 9. Geo‑replication

With **Premium** SKU you can configure **geo‑replication**:

- Create **replicas** of your registry in multiple regions.
- Single logical registry, multiple regional endpoints.
- Images are pushed once and automatically replicated.
- Container hosts pull from the nearest replica → lower latency.

Use cases:

- Global applications running in several Azure regions.
- Disaster recovery: if one region is down, others can still pull images.

---

## 10. Exam summary for ACR

1. **ACR is a private registry** for container images in Azure.
2. Know **registry vs repository vs image vs tag**.
3. Understand **SKUs** and that **Premium** adds **geo‑replication**.
4. Prefer **Azure AD identities + AcrPull/AcrPush roles** over admin user.
5. Remember **ACR Tasks** for automated builds in Azure.
6. Use **retention policies** to clean untagged images.
7. Use **private endpoints / firewall rules** to restrict access.
8. ACR is the typical image source for **ACI, Container Apps, AKS, App Service** in exam scenarios.

# Provision a container by using Azure Container Apps

## 1. Concept overview

### What is Azure Container Apps?

Azure Container Apps (ACA) is a **serverless container platform** built on top of Kubernetes, Envoy, and KEDA (for autoscaling).  
It lets you run containerized applications **without managing Kubernetes**, while still getting powerful features:

- HTTP **ingress** with automatic TLS.
- **Automatic scaling** based on HTTP traffic or events (queues, topics, etc.).
- **Revisions** and **traffic splitting** for blue‑green and A/B deployments.
- Optional integration with **Dapr** for microservices (service invocation, pub/sub, state, bindings).

**Typical use cases**

- Public APIs and web backends.
- Background workers processing messages from queues.
- Event‑driven microservices.
- Small to medium microservice architectures where you do **not** want to manage AKS.

**Exam angle:**  
If the question mentions **“serverless containers with automatic scaling and HTTP ingress, no Kubernetes management”**, the answer is likely **Azure Container Apps**.

---

## 2. Key Container Apps concepts

### 2.1 Container Apps environment

- A **Container Apps environment** is the **secure boundary** in which your apps run.
- It maps to one or more underlying Kubernetes clusters managed by Microsoft.
- It defines:
  - **Network** (VNet or public).
  - Shared **Log Analytics workspace** for logs.
  - Region.

You deploy one or more **container apps** inside the same environment.

### 2.2 Container app, revisions, and replicas

- A **container app**:
  - One logical application (for example `orders-api`).
  - Contains one or more containers (usually one main container).
- **Revisions**:
  - Each time you change configuration (image, environment variables, scaling rules, etc.), a new **revision** is created.
  - You can control:
    - **Single revision** mode – only the latest revision is active.
    - **Multiple revision** mode – several revisions active at the same time, with **traffic split** between them (for example 80% old, 20% new).
- **Replicas**:
  - When Container Apps **scales out**, it creates multiple **replicas** (instances) of a revision.

### 2.3 Scaling with KEDA

- Container Apps uses **KEDA (Kubernetes Event‑Driven Autoscaling)**.
- You define **scale rules** such as:
  - HTTP concurrent requests.
  - Queue length (Azure Storage queues, Service Bus, etc.).
  - Custom metrics.
- Container Apps can scale:
  - **Out** to many replicas when load increases.
  - **To zero** when there is no traffic (for cost savings) for supported rule types.

---

## 3. Provisioning a Container App using the Azure portal

The exam objective explicitly says **“in the Azure portal”**, so focus on portal steps.

### Step 1 – Create a Container Apps environment (if you don’t have one yet)

1. In the portal, search for **“Container Apps”**.
2. Click **Create**.
3. On the **Basics** tab:
   - Subscription and resource group.
   - Container app name (for example `orders-api`).
   - Region (for example West Europe).
4. Choose **Container Apps environment**:
   - Create a new environment or select existing.
   - For a new environment:
     - Give it a name.
     - Select region (usually same as the app).
     - Networking:
       - **Internal** environment – for private apps in a VNet.
       - **External** environment – apps can have public ingress.
5. **Log Analytics**:
   - Select or create a **Log Analytics workspace** for logging and metrics.
6. Proceed to the **App** configuration tab (still within the same wizard).

Note: In newer portal flows, environment creation might be a separate step; conceptually it is the **shared host** for multiple apps.

### Step 2 – Choose container source

On the **Container** or **App** tab you define the image:

- **Container type**:
  - Single container (common).
- **Container image source**:
  - **Quickstart image** – for demos (for example `mcr.microsoft.com/azuredocs/containerapps-helloworld:latest`).
  - **Azure Container Registry** – typical for production.
  - Other registries (with credentials).
- If using **ACR**:
  - Select ACR and the image tag.
  - Ensure the environment or app has permissions (managed identity + AcrPull role).

### Step 3 – Ingress settings

- Enable or disable **ingress**:
  - Disable: for internal / background worker apps (no direct HTTP access).
  - Enable: for HTTP‑based services and APIs.
- If ingress enabled:
  - Choose **Ingress type**:
    - External (public).
    - Internal (only inside VNet / environment).
  - Choose **target port** (for example `80` or `8080`).
  - Optionally specify **custom domain** and certificate later.

### Step 4 – Resource sizing (CPU and memory)

For the container:

- Set **CPU** (for example 0.25, 0.5, 1, 2 vCPU).
- Set **memory** (for example 0.5 GiB, 1 GiB, 2 GiB).

These values are **per replica**. More replicas = more total capacity and cost.

---

## 4. Configuring scaling rules

On the **Scale** tab:

### 4.1 Basic limits

- **Minimum replicas**:
  - Number of replicas that must always run.
  - Set to 0 to **scale to zero** when there’s no traffic (cost saving).
- **Maximum replicas**:
  - Upper limit of replicas (for example 10 or 50).
  - Prevents uncontrolled growth.

### 4.2 HTTP scaling

When ingress is enabled, you can add a **scale rule** based on HTTP:

- **Concurrency**: maximum simultaneous HTTP requests per replica.
- If concurrency threshold is exceeded, Container Apps creates new replicas up to the max.

Example:

- Min replicas: 1  
- Max replicas: 10  
- Target concurrency: 50 requests per replica  

If there are 250 concurrent requests, Container Apps can scale to about 5 replicas to handle the load.

### 4.3 Event‑driven scaling

You can also scale based on external events (KEDA scalers):

- Azure Service Bus queue length.
- Azure Storage queue length.
- Custom events (Prometheus, HTTP).
- Dapr pub/sub messages.

Example scenario:

- Scale from 0 to 20 replicas when Service Bus queue length > 100 messages.

---

## 5. Environment variables, secrets, and identity

### 5.1 Environment variables and secrets

- Define **environment variables** (configuration).
- Store sensitive values as **secrets**:
  - Connection strings.
  - API keys.
  - Other credentials.

You then **reference secrets** in environment variables so that secrets are not shown in plain text.

### 5.2 Managed identity

- Container Apps can use **system‑assigned** or **user‑assigned managed identities**.
- Use cases:
  - Access Key Vault.
  - Pull images from ACR.
  - Call other Azure services securely (SQL, Storage, Service Bus).

Exam scenario:  
If the question says **“use managed identity from the container to access Key Vault secrets”**, Container Apps supports this directly.

---

## 6. Revisions and traffic splitting

### 6.1 Revision modes

Container Apps supports different revision modes:

- **Single revision**:
  - Only the latest revision is active.
  - Old revision is deactivated when new one is deployed.
- **Multiple revisions**:
  - Multiple revisions can be active at the same time.
  - You can split HTTP traffic between them (for example v1 = 70%, v2 = 30%).

### 6.2 Common patterns

- **Blue‑green deployment**:
  - Revision A (blue) receives 100% traffic.
  - Deploy revision B (green), but initially 0% traffic.
  - Switch gradually from blue to green.
- **A/B testing**:
  - Revision A = current version (80% traffic).
  - Revision B = experimental feature (20% traffic).
  - Evaluate performance and then move 100% to the better revision.

This is a strong feature of Container Apps that you should recognize in exam questions about **gradual rollout** or **A/B testing**.

---

## 7. Monitoring and diagnostics

When creating the environment you link to a **Log Analytics workspace**. Container Apps sends:

- Container stdout/stderr logs.
- Ingress logs and metrics.
- System events and scaling information.

You can:

- View logs from the **Logs** blade using Kusto queries.
- Monitor performance with Azure Monitor metrics.
- Set **alerts** on CPU, memory, or custom metrics.

Monitoring is similar to other Azure PaaS services, but the key is that **everything is collected at environment level** in Log Analytics.

---

## 8. Security and networking

### 8.1 Networking options

- **Environment in a VNet**:
  - Container Apps environment can be attached to a **virtual network**.
  - Apps then get internal addresses and can talk to private resources.
- **Ingress**:
  - Public (external) ingress for internet‑facing APIs.
  - Internal ingress only for internal microservices.

### 8.2 Securing access

- For public APIs:
  - Use **certificates** and **HTTPS**.
  - Restrict access with **Web Application Firewall (WAF)** on Application Gateway or Front Door if needed.
- For internal apps:
  - Use internal ingress and VNet integration so apps are only accessible from inside the network.

### 8.3 Image security

- Prefer **ACR** as image source.
- Use managed identity + AcrPull role instead of embedded credentials.

---

## 9. Comparing Container Apps vs ACI vs AKS (exam view)

| Feature / Need                            | ACI                            | Container Apps                                  | AKS (Kubernetes)                     |
|------------------------------------------|--------------------------------|-------------------------------------------------|--------------------------------------|
| Who manages Kubernetes?                  | Not used                       | Microsoft (fully managed)                       | You (cluster admin)                  |
| Automatic HTTP/event scaling             | Basic / external only          | Built‑in (KEDA)                                 | With HPA/KEDA                        |
| Scale to zero                            | Limited (run‑once jobs)        | Native                                          | With custom setup                    |
| Best for                                 | Simple jobs, dev/test          | Serverless microservices & APIs                 | Complex, large, highly customized    |
| Portal‑driven container deploy with autoscale | Possible but manual           | Yes, directly in the portal                     | Possible but more complex            |

**Key exam takeaway:**  
When you see **“serverless containers with autoscaling and HTTP ingress, minimal ops”** → think **Azure Container Apps**, not ACI.

---

## 10. Exam summary for Container Apps

1. Container Apps = **serverless container platform** on top of Kubernetes + KEDA.
2. You deploy apps into a **Container Apps environment**.
3. Each app has **revisions** and **replicas**; revisions support **traffic splitting**.
4. Autoscaling:
   - Min / max replicas.
   - HTTP concurrency.
   - Event‑driven KEDA scalers (queues, topics, custom metrics).
5. Supports **scale to zero** for cost savings.
6. Great for **microservices, APIs, event‑driven workers** where you do not manage Kubernetes directly.
7. Integrates with **ACR**, **managed identity**, **Key Vault**, Log Analytics.

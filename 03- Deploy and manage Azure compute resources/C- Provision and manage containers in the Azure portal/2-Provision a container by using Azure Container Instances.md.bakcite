# Provision a container by using Azure Container Instances (ACI)

## 1. Concept overview

### What is Azure Container Instances?

Azure Container Instances (ACI) is a **serverless container runtime** in Azure.  
You can run **Linux or Windows containers** without managing virtual machines or a full Kubernetes cluster.

You only specify:

- Container image
- CPU and memory
- Environment variables / secrets
- Networking options

Azure starts the container **within seconds** and you pay **per second** for what you use.

**Typical use cases**

- Simple APIs or microservices that do not need complex orchestration.
- Short‑lived **batch jobs** or **scheduled tasks**.
- Development and testing environments.
- Event‑driven tasks (triggered by Azure Functions, Logic Apps, etc.).

**Exam angle:**  
ACI is often contrasted with **AKS** and **Azure Container Apps**:

- Need **fast, simple container** with no orchestration → **ACI**.
- Need **autoscaling + HTTP ingress + microservices** → **Container Apps** or **AKS**.

---

## 2. Core ACI concepts

### Container group

In ACI, the basic deployment unit is a **container group**:

- One or more containers that **share**:
  - The same host machine.
  - The same lifecycle (start, stop together).
  - The same network interface and IP.
  - The same volumes.

For most scenarios and for the exam, you will run **a single container** in a group.

### Image sources

ACI can run images from:

- **Azure Container Registry (ACR)** – most common in exam.
- Public registries like **Docker Hub**.
- Other private registries (with credentials).

### OS types and regions

- Supports **Linux** and **Windows** containers (region dependent).
- Not every region supports all OS types; in the exam questions, Azure will pick valid regions for you.

---

## 3. Deploying ACI using the Azure portal

### Step 1 – Start the wizard

1. In the portal, search for **"Container instances"**.
2. Click **Create**.

### Step 2 – Basics

- **Subscription**: choose the correct one.
- **Resource group**: existing or create new.
- **Container name**: DNS‑friendly name (for example `orders-api`).
- **Region**: choose a region close to users or other services.

### Step 3 – Image and OS

- **Image source**:
  - **Docker Hub or other registry** – for public images like `mcr.microsoft.com/azuredocs/aci-helloworld`.
  - **Azure Container Registry** – select your ACR and image.
- **Image type**: Public / Private.
- **Operating system**: Linux or Windows.
- If using **private ACR**, you must configure authentication:
  - Often via **managed identity** or using **ACR admin account** for labs.

### Step 4 – Size (CPU and memory)

Choose **vCPU** and **memory** for the container group:

- Example: 1 vCPU, 1.5 GiB RAM for a small web API.
- Higher values = more performance + higher cost.

### Step 5 – Networking

Main options:

- **DNS name label**:
  - If enabled, your container gets a public FQDN like:
    - `orders-api.eastus.azurecontainer.io`
  - Good for simple public endpoints.
- **Ports**:
  - Expose specific ports (for example 80 or 443).
- **Virtual network**:
  - You can deploy the container group into a **VNet subnet**.
  - This gives it a **private IP** and lets it talk securely to other private resources (databases, web apps, etc.).

Exam scenario:  
If the requirement is _"run a container with a private IP in a subnet and no public access"_, you must **deploy ACI into a VNet** and disable the public IP.

### Step 6 – Advanced (environment, restart policy, volumes)

- **Environment variables**:
  - Add key/value pairs (for example `ASPNETCORE_ENVIRONMENT=Production`).
- **Command override**:
  - Optionally override the default container command.
- **Restart policy**:
  - **Always** – restart container if it stops. Good for long‑running services.
  - **OnFailure** – restart only when exit code != 0.
  - **Never** – good for **run‑once jobs** so they stop and you stop paying.
- **Volumes**:
  - Mount an **Azure Files share** as a volume for persistent data.

### Step 7 – Review + create

Review configuration and **Create**.  
Within seconds, the container group should start.

---

## 4. Accessing and testing your container

### Public container with DNS name label

If you enabled a DNS label and exposed port 80:

- Browse to:
  ```text
  http://<dns-name-label>.<region>.azurecontainer.io
  ```

Example: `http://orders-api.westeurope.azurecontainer.io`.

### Private container in a VNet

- Use a VM or other resource inside the same VNet/subnet to access it via **private IP**.
- You might use **Azure Bastion** or a jumpbox VM to reach that environment.

---

## 5. Integrating with Azure Container Registry (ACR)

Most production scenarios use **ACR** as the image source:

1. Build and push image to ACR (see previous file).
2. Give ACI permission to pull from ACR:
   - Either:
     - Turn on **system‑assigned managed identity** for the container group and give it **AcrPull** on ACR.
     - Or (for labs) use the ACR **admin user** credentials.
3. In the portal create container instance:
   - Image source: **Azure Container Registry**.
   - Select registry and image tag.

**Exam angle:**  
If the question talks about **“using a private registry inside Azure”**, the answer is almost always **Azure Container Registry + ACR authentication**.

---

## 6. Monitoring and troubleshooting ACI

### Container logs

- In the container instance blade, select **Containers** → your container → **Logs**.
- Shows `stdout` and `stderr` from the container.
- Useful for runtime errors, crashes, etc.

### Events and status

- The **Events** tab shows:
  - Image pull errors.
  - Resource limitations.
  - Scheduling issues.

### Metrics and Azure Monitor

- You can enable diagnostics to send logs and metrics to:
  - **Log Analytics workspace**
  - **Storage account**
  - **Event hub**

Common metrics:

- CPU usage, memory usage.
- Running / stopped container count.
- Restart count.

---

## 7. Scaling with ACI (high level)

ACI itself does **not** have rich, built‑in autoscaling for HTTP traffic. You normally:

- Manually create multiple container groups.
- Use ARM/Bicep, Azure CLI, or scripts to deploy N instances.
- Or use other Azure services (Functions, Logic Apps, AKS) to orchestrate scale‑out.

If the requirement is **“automatic scaling based on HTTP traffic or queue length”**, ACI alone is **not enough**. You would use:

- **Azure Container Apps** (serverless, event‑driven autoscale), or
- **AKS with HPA/KEDA**.

This distinction is important for AZ‑104 scenario questions.

---

## 8. Security considerations

- Use **private images** in ACR instead of public Docker Hub for production.
- Prefer **managed identity + AcrPull** role instead of hard‑coded credentials.
- Deploy to **VNets** and use **private IPs** when accessing databases or internal APIs.
- Limit public access using **NSGs**, **Application Gateway**, or **firewalls** in front of services that call ACI.

---

## 9. Exam summary for ACI

1. ACI runs containers without VMs or Kubernetes; **fast, simple, per‑second billing**.
2. You deploy a **container group** with one or more containers.
3. You choose:
   - Image (often from **ACR**),
   - CPU/memory,
   - OS (Linux/Windows),
   - **Restart policy** (Always / OnFailure / Never),
   - Networking (public IP + DNS label or VNet with private IP).
4. ACI is ideal for:
   - Short‑lived jobs,
   - Simple APIs,
   - Dev/test.
5. ACI **does not provide advanced autoscaling** — for that, use **Container Apps or AKS**.
6. Logs and events are available directly in the portal and via **Azure Monitor / Log Analytics**.

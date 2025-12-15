# Manage sizing and scaling for containers (ACI and Azure Container Apps)

This topic focuses on **how to choose CPU/memory** and **how to scale** containers in:

- **Azure Container Instances (ACI)**
- **Azure Container Apps**

Understanding sizing and scaling is very common in AZ‑104 scenario questions.

---

## 1. Sizing basics – CPU, memory, and concurrency

### 1.1 CPU and memory

Every container needs:

- **CPU (vCPUs)** – processing power.
- **Memory (GiB)** – RAM used by the application.

If you **under‑size**:

- App might be slow, crash with OOM (out‑of‑memory) errors.

If you **over‑size**:

- Costs increase without benefit.

General guidelines:

- Small API / worker: start with **0.25–0.5 vCPU** and **0.5–1 GiB**.
- Heavier workloads: increase CPU and memory gradually.

### 1.2 Horizontal vs vertical scaling

- **Vertical scaling** = give one instance more CPU/memory.
- **Horizontal scaling** = add more instances (replicas).

In containers:

- Vertical scaling is **changing resource limits** for each instance.
- Horizontal scaling is **adding replicas** (more container instances).

Container Apps and AKS usually rely more on **horizontal scaling**.

---

## 2. Sizing and scaling in Azure Container Instances (ACI)

### 2.1 Sizing ACI containers

When you create an ACI container group you specify:

- Number of **vCPUs** (for example 1 or 2).
- Amount of **memory** (for example 1.5 GiB, 4 GiB).

The resource values apply to the **whole container group** (shared by its containers).

Key points:

- Pricing is based on **vCPU‑seconds** and **GB‑seconds** of memory usage – you pay only while the container runs.
- You can choose Linux or Windows as OS.
- For GPU workloads, specific SKUs/regions support GPU‑enabled ACI (not deeply tested on AZ‑104 but good to know).

### 2.2 Scaling ACI – what is and is not supported

ACI is **simple**:

- It does **not** provide built‑in autoscaling based on CPU or HTTP traffic.
- Each container group is a **stand‑alone deployment**.

To scale:

- **Manual horizontal scaling**:
  - Create multiple container groups (for example `orders-api-1`, `orders-api-2`, `orders-api-3`).
  - Put an **Azure Application Gateway**, **Azure Front Door**, or **Traffic Manager** in front to distribute traffic.
- **Scripted scaling**:
  - Use automation (PowerShell, CLI, Logic Apps, Functions) to create/delete container instances based on metrics.

ACI works well for:

- **Run‑once jobs** – where scaling may just mean running more jobs in parallel.
- Simple APIs where you might manually increase instance count.

**Exam angle:**  
If the question asks for **“automatic scaling of containers based on demand”**, pure ACI is **not** the best answer. The correct answer is usually **Azure Container Apps** or **AKS**.

### 2.3 Restart policy and cost control

Remember the **restart policy** behaves like a simple scaling/availability control:

- `Always` – ACI restarts your container when it stops (good for long‑running services).
- `OnFailure` – restarts only when exit code != 0.
- `Never` – for **run‑once jobs** (builds, data processing) – when the job finishes, the container remains stopped and you stop paying.

---

## 3. Sizing and scaling in Azure Container Apps

Azure Container Apps provides **rich, built‑in scaling** powered by **KEDA**.

### 3.1 Sizing per replica

For each Container App, you choose:

- vCPU (for example 0.25, 0.5, 1, 2)
- Memory (for example 0.5 GiB, 1 GiB, 2 GiB)

This defines the resources for **a single replica**.

Total capacity = `replicas × (vCPU, memory)`.

Example:

- 0.5 vCPU / 1 GiB per replica.
- Max 10 replicas.
- **Total possible compute** = up to 5 vCPU and 10 GiB memory.

### 3.2 Minimum and maximum replicas

On the **Scale** tab:

- **Minimum replicas**:
  - Set to 0 → app can **scale to zero** when idle.
  - Set to 1+ → at least that many instances always running (useful for latency‑sensitive apps).
- **Maximum replicas**:
  - Hard upper limit to control costs and protect backends.

Example:

- Min replicas: 1  
- Max replicas: 20  

Your app will always have at least one replica, but never more than 20.

### 3.3 HTTP scaling

Container Apps can scale automatically based on **HTTP traffic**:

- You set **target concurrency** (for example 50 requests per replica).
- Container Apps monitors how many concurrent requests each replica handles.
- If the load exceeds the target, KEDA adds more replicas up to the max.

Example:

- Target concurrency: 50.  
- Current concurrency: 200.  
- System could scale to 4 replicas (approx) to keep 50 requests per replica.

This is what makes Container Apps perfect for **bursting web traffic**.

### 3.4 Event‑driven scaling (queues, topics, etc.)

You can scale based on external events such as:

- Azure Storage queues – scale based on **queue message count**.
- Azure Service Bus queues or topics – scale based on backlog.
- Custom metrics exposed via Prometheus or HTTP.
- Dapr pub/sub events.

Example rule:

- Scale from 0 to 30 replicas when queue length > 100.
- Scale back down as messages are processed.

### 3.5 Preventing “flapping” (too frequent scale in/out)

Good practices:

- Avoid very low cool‑down periods.
- Set realistic thresholds so minor spikes do not trigger scale events.
- Keep a small **minimum replica** count for latency‑sensitive APIs to avoid cold starts.

---

## 4. Comparing ACI vs Container Apps for scaling

| Area                         | Azure Container Instances                 | Azure Container Apps                                    |
|------------------------------|-------------------------------------------|--------------------------------------------------------|
| Resource definition          | vCPU + memory per container group         | vCPU + memory per replica                              |
| Autoscaling engine           | None built‑in                             | KEDA (event‑driven autoscaling)                        |
| Scale to zero                | Possible for run‑once jobs (Never policy) | Native support with min replicas = 0                   |
| HTTP scaling                 | Not built‑in                              | Built‑in HTTP concurrency scaling                      |
| Event‑driven scaling         | External tooling only                     | Built‑in KEDA scalers (queues, topics, custom metrics) |
| Operational complexity       | Very low                                  | Low‑medium (more knobs)                                |
| Typical exam identity        | “Run a single container quickly”          | “Serverless container with autoscale & ingress”        |

**Exam hint:**

- **Need auto scale, traffic split, scale‑to‑zero, microservices** → **Container Apps**.
- **Need simple ad‑hoc job or quickly run a container** → **ACI**.

---

## 5. Example scenarios (exam‑style thinking)

### Scenario 1 – Nightly batch job

You run a container every night at 01:00 that processes data and then exits.

- **Best service**: Azure Container Instances.
- **Sizing**: Enough CPU/memory to finish in time (for example 2 vCPU, 4 GiB).
- **Restart policy**: `Never` – job stops when done and you stop paying.
- Trigger with Logic App, Azure Function, or Automation.

### Scenario 2 – Public HTTP API with unpredictable traffic

You have an API that must handle sudden spikes and should scale automatically.

- **Best service**: Azure Container Apps.
- **Sizing**: Start with 0.5 vCPU / 1 GiB per replica.
- **Scale**:
  - Min replicas: 0 or 1 (if low latency is important).
  - Max replicas: 20.
  - HTTP scale rule with concurrency 50.

### Scenario 3 – Background worker for queue processing

Messages are pushed to an Azure Storage queue. When queue increases, you need more worker instances.

- **Best service**: Azure Container Apps with **queue‑based KEDA scaler**.
- Set min replicas = 0, max replicas = 30.
- Scale out when queue length > N (for example 100 messages).

### Scenario 4 – One‑off containerization test

Developer wants to run a containerized tool for a few hours to test something.

- **Best service**: ACI (simple, pay‑per‑second).
- Manual scaling if needed (for example run two instances in parallel).

---

## 6. Best practices for exam and real life

1. **Start small, monitor, then adjust**:
   - Use Azure Monitor + Log Analytics to track CPU/memory.
   - Increase or decrease vCPUs and memory based on real usage.
2. **Use autoscaling where possible**:
   - Container Apps + KEDA for modern workloads.
   - Avoid building your own scaling engine unless necessary.
3. **Protect backends**:
   - If scaling containers aggressively, ensure databases and APIs can handle the load.
   - Use max replicas to protect downstream systems.
4. **Cost awareness**:
   - High CPU/memory per replica + high replica count = high cost.
   - Scale‑to‑zero patterns in Container Apps save a lot for sporadic workloads.
5. **Security and networking**:
   - For both ACI and Container Apps, prefer:
     - Private images from ACR.
     - VNet integration for backend access.
     - Managed identities instead of hard‑coded credentials.

---

## 7. Exam summary

- Know **how to choose CPU/memory** and when to scale up vs scale out.
- Understand that **ACI** is simple and does **not** have rich built‑in autoscaling; you manage scale yourself.
- Understand that **Azure Container Apps** provides:
  - Min/max replicas.
  - HTTP concurrency‑based scaling.
  - Event‑driven scaling with KEDA.
  - Optional scale‑to‑zero.
- Be able to pick the right service and scaling approach based on **scenario descriptions** in AZ‑104 questions.

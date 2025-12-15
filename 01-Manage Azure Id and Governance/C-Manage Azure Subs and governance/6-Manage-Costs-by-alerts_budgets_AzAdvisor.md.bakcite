# Manage Costs by Using Alerts, Budgets, and Azure Advisor Recommendations

## Budgets

### Purpose

Used to control costs by setting spending limits.

### Scope

Can be applied at Management Group, Subscription, or Resource Group level.

### Action

- Budgets do not stop resources or spending.
- They only trigger alerts (email, Action Groups, automation like Logic Apps/Functions).

### Types

- Actual Cost → Tracks what you've already spent.
- Forecasted Cost → Predicts future spending based on current trends.

### Reset Period

Budgets automatically reset to start fresh:
- Monthly
- Quarterly
- Annually

### Best use case for exam

"Set a budget at subscription level for $500/month, when spend reaches 80% send alert, at 100% trigger automation."
Know: Alerts = notification/automation, not blocking usage.

**✅ Key Exam Tip:** If the question asks "Can budgets stop or enforce cost limits?" → Answer = No, they only alert/automate.

---

## Alerts

### Budget Alerts

- Trigger when spend hits a threshold you set (ex: 80%, 100% of budget).
- Based on actual cost or forecasted cost.

### Delivery / Integration

Alerts use Action Groups (a collection of actions).

Action Group can send:
- Email
- SMS
- Push notification
- Webhook (integrate with apps)
- ITSM tools (like ServiceNow)

### Important Limitation

- Alerts do not stop resources or prevent further spending.
- To take action, combine with automation:
  - Logic Apps
  - Azure Functions
  - Automation Runbooks

**✅ Key Exam Tip:** If a question asks:
- "You want to be notified at 80% spend but still allow resources to run" → Budget Alert.
- "You want resources to shut down when budget exceeded" → Not possible directly. Must use automation with alerts.

---

## Azure Advisor Recommendations

### What it is

Free service that analyzes your environment and gives best-practice guidance.

### Categories of Recommendations

**Cost** → Save money (optimize resources).
Example: A VM that's running at 5% CPU → Advisor says "resize to smaller VM".

**Reliability (High Availability)** → Improve availability/disaster recovery.
Example: Your backup isn't configured → Advisor says "enable backup for this VM".

**Security** → Protect your resources. Advisor pulls data from Defender for Cloud.
Example: A storage account allows public access → Advisor warns "disable public access".

**Performance** → Make your apps run faster.
Example: VM disk is too slow (Standard HDD) → Advisor says "move to Premium SSD".

**Operational Excellence** → Improve how you manage and govern resources.
Example: You deployed resources without tags → Advisor says "add tags for better cost tracking".

**Easy way to remember:**
- Cost = 💰 Save money
- Reliability = 🔄 Stay online
- Security = 🔐 Stay safe
- Performance = ⚡ Run faster
- Operational Excellence = 📋 Work smarter

**✅ Key Exam Tip:**
If the question asks "How do you identify and reduce waste/underused resources?" → Azure Advisor (Cost category).
If the question asks "Does Advisor enforce recommendations?" → No, it only advises. Enforcement requires Azure Policy.

---

## Cost Analysis (Azure Cost Management + Billing)

### Purpose

Tool to visualize and analyze cloud spending.
Can view costs by Subscription, Resource Group, Service type, Location, etc.

### Filtering & Grouping

- Use Tags (e.g., Department, Project, Environment) to slice costs by business unit.
- Example: See total spend for all resources tagged Department = HR.

### Scopes

**Billing Account Scope** → Shows costs for all subscriptions under that billing account.
Example: An Enterprise Agreement (EA) account covering multiple subs.

**Subscription Scope** → Shows costs for a single subscription only.

**✅ Key Exam Tip:**
If you need to view costs for one subscription → use Subscription Scope.
If you need to view costs across multiple subscriptions (like enterprise level) → use Billing Account Scope.
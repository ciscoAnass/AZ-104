# Apply and Manage Tags on Resources

## A. Tag Basics

**Definition** → Tags are key-value pairs (like labels).
Example: Environment=Prod, Department=IT, Owner=Alice.

**Purpose** → Help with:
- Organizing resources.
- Tracking costs (you can filter billing by tags).
- Automation (scripts/policies can use tags).

## B. Scopes of Tags

You can apply tags at:
- Resource (e.g., a VM).
- Resource Group (RG).
- Subscription.

**Important:** Tags don't automatically flow down.
If you tag the RG with Department=HR, the resources inside don't inherit it automatically.

## C. Inheritance

To enforce inheritance, you need:
- Azure Policy (e.g., "Append a tag to resources").
- Or automation (Azure CLI, PowerShell, ARM/Bicep, Terraform).

## D. Limits

- Max 50 tags per resource.
- Key: up to 512 characters.
- Value: up to 256 characters.
- Case-insensitive for key/value, but case is preserved.

## E. Billing & Management

- Tags show up in Cost Management + Billing reports.
- Useful for chargeback/showback (assigning cloud costs to departments, projects, etc.).
- Some resources don't support tags (rare, but exam might test this fact).

## Exam Key Points (easy to remember)

- Tags = key-value labels (organization + cost tracking).
- Apply at RG, resource, or subscription.
- NO automatic inheritance → need policy/automation.
- Limit = 50 tags per resource.
- Billing: Tags used in cost reporting.

## Best Practices (extra details)

**Standardize tag structure** → Always agree on consistent spelling (Env vs Environment, avoid mismatches).

**Enforce with Policy** → Example: Policy that denies resource creation if required tag is missing.

**Use in Billing** → Cost Management + Billing reports can group/filter by tag for chargeback/showback.
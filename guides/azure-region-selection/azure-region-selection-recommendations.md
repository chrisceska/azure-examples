# Recommendations for Selecting an Azure Region for a New Application

Created: 2026-03-15

## Executive summary

Selecting an Azure region is an architecture decision, not a deployment detail. The region you choose influences legal compliance, data residency, application latency, service availability, resiliency design, disaster recovery options, quota and capacity risk, pricing, network topology, and operational complexity.

For most new production applications, start by identifying the smallest set of regions that satisfy hard constraints: data residency, regulatory requirements, customer geography, required Azure services, and required SKUs. From that shortlist, prefer a region close to the primary user population that supports availability zones for the application's critical services. If the workload has high availability or business continuity requirements that exceed what one region can provide, select a secondary region deliberately based on recovery objectives, latency, compliance boundaries, replication support, capacity, and operational readiness.

The recommended default is:

1. Choose a primary region in the required Azure geography, close to the primary users or dependent systems.
2. Prefer a region with availability zones and deploy critical components in a zone-resilient pattern where the services support it.
3. Verify that every required Azure service, SKU, feature, quota, and compliance requirement is available in the candidate region before committing.
4. For production workloads, define the disaster recovery strategy at the same time as the primary region decision.
5. Document the decision and revisit it when the application expands to new users, new regulatory boundaries, new services, or materially higher scale.

## Core principle

Do not select a region solely because it is familiar, close to the development team, or commonly used by the organization. Select the region that best fits the workload's users, data, reliability goals, required services, and operating constraints.

The best region for one workload might be the wrong region for another workload in the same company. A customer-facing web app, an internal analytics platform, a regulated healthcare workload, a low-latency trading application, and an AI inference service can each have different region requirements.

## Decision order

Use this order when narrowing candidate regions:

| Order | Decision area | Why it matters |
| --- | --- | --- |
| 1 | Data residency, sovereignty, and compliance | Some requirements are non-negotiable and can eliminate otherwise attractive regions. |
| 2 | Required services, SKUs, and features | Not every Azure service, feature, VM size, zone capability, or preview is available in every region. |
| 3 | User and dependency latency | Physical and network proximity affect user experience and service-to-service performance. |
| 4 | Availability zone support | Zone-capable regions give better in-region fault isolation for production workloads. |
| 5 | Disaster recovery and multi-region strategy | Region choice affects replication, failover, recovery time, recovery point, and operating complexity. |
| 6 | Capacity and quota | A region can be technically correct but practically constrained for large deployments or scarce SKUs. |
| 7 | Cost | Regional price differences can matter, but cost should not override compliance or reliability needs. |
| 8 | Operational fit | Monitoring, support coverage, network connectivity, landing zones, policy, and team readiness affect long-term success. |

## Step-by-step selection process

### 1. Define the workload's non-negotiable requirements

Before looking at a region list, write down the constraints that must be true for the application to launch.

Capture:

- Where users are located.
- Where customer data originates.
- Whether data must remain in a specific country, region, geography, sovereign cloud, or tenant boundary.
- Which industry standards, contractual terms, or government requirements apply.
- Whether the workload handles personal data, financial data, health data, export-controlled data, confidential customer data, or other regulated data.
- Required recovery time objective (RTO) and recovery point objective (RPO).
- Required uptime or service level target.
- Expected scale at launch and at 6, 12, and 24 months.
- Required Azure services, SKUs, VM families, database tiers, AI models, networking features, and marketplace products.
- Dependencies on on-premises systems, partner systems, SaaS platforms, identity providers, or other Azure workloads.

If a requirement is mandatory, mark it as mandatory. If it is a preference, mark it as a preference. This prevents a low-priority factor, such as cost or team familiarity, from accidentally overriding a compliance or reliability requirement.

### 2. Identify the required Azure geography

Azure regions are grouped into geographies. A geography is a data residency boundary, such as the United States or Europe. If the application has data residency requirements, first identify which Azure geography is allowed.

For example:

- A workload serving only EU customers might need regions in the Europe geography.
- A workload serving US government customers might need Azure Government rather than global Azure.
- A workload subject to strict country-level requirements might need a region located in that country or a specific sovereign cloud.
- A global SaaS workload might need multiple regional deployments, each serving a specific residency boundary.

Recommendation: Treat data residency as a design boundary, not an afterthought. If the application stores customer data in a region outside the required boundary, later remediation can require data migration, architecture changes, customer notifications, contract changes, or regulatory review.

### 3. Create a candidate region shortlist

Build a shortlist of regions that satisfy the mandatory geography, compliance, and availability requirements. Do not evaluate every Azure region equally. Remove regions that are unavailable to the subscription, restricted, missing required services, or outside the legal boundary.

For each candidate region, record:

- Azure region name, such as `eastus`, `westeurope`, or `uksouth`.
- Display name, such as East US, West Europe, or UK South.
- Geography.
- Whether the region supports availability zones.
- Whether the required services support zone-redundant or zonal deployment in that region.
- Whether the required services and SKUs are available.
- Whether the region has a paired region, if that matters for a service you plan to use.
- Expected latency to users and critical dependencies.
- Known quota or capacity risks.
- Estimated cost.
- Any organization-specific restrictions or preferred landing zones.

Useful Azure CLI checks:

```azurecli
az account list-locations \
  --query "[].{Name: name, DisplayName: displayName}" \
  --output table
```

```azurecli
az account list-locations \
    --query "[?availabilityZoneMappings].{availabilityZoneMappings: availabilityZoneMappings, displayName: displayName, name: name}"
```

The first command lists regions available to the subscription. The second command helps inspect availability zone mappings for regions that expose them to the subscription.

### 4. Validate required Azure service availability

Not all Azure services are available in all regions. Even when a service is available, a specific feature, tier, SKU, VM family, availability zone mode, model, capacity type, or preview feature might not be available.

For each required service, validate:

- Is the service available in the candidate region?
- Are the required tiers or SKUs available?
- Are the required features available in that region?
- Does the service support availability zones in that region?
- Does the service support zone-redundant deployment, zonal deployment, or only regional deployment?
- Does the service support cross-region replication or failover from the selected region?
- Are there service-specific limitations for sovereign clouds or restricted regions?
- Are there quota limits that could block the planned scale?

Examples:

- A VM-based workload might need a specific VM family that is not available everywhere.
- A database service might be available in a region but not support zone redundancy there.
- An AI workload might need a particular model, deployment type, or capacity pool that is region-limited.
- A storage account might support geo-redundancy only to a specific paired region when using some replication options.
- A managed service might be available globally but store metadata or control-plane data in a different geography unless configured carefully.

Recommendation: Validate service availability before finalizing architecture diagrams, cost estimates, or customer commitments. Region changes late in a project often ripple through networking, identity, disaster recovery, data migration, performance testing, and compliance approvals.

### 5. Prioritize latency to users and dependent systems

For interactive applications, choose a region close to the users who perform latency-sensitive actions. Lower latency improves page load times, API responsiveness, real-time collaboration, authentication flows, and perceived reliability.

Consider latency to:

- End users.
- Mobile users.
- Branch offices.
- Partner APIs.
- On-premises datacenters.
- Identity providers.
- Payment providers.
- Data platforms.
- Existing Azure workloads.
- Monitoring and logging endpoints.
- Third-party SaaS integrations.

Latency is not only about distance from users. It is also affected by network routing, private connectivity, peering, DNS, content delivery, TLS termination, service dependencies, and whether calls cross regions. A region close to users might still perform poorly if the database, identity provider, or core dependency is far away.

Recommendation: Measure latency using realistic client locations and realistic network paths. Do not rely only on developer workstation tests. Test from representative user locations, virtual networks, ExpressRoute paths, VPN paths, and application components.

### 6. Prefer availability zone-capable regions for production

Availability zones are physically separate groups of datacenters within an Azure region. They have independent power, cooling, and networking. A region with availability zones can support stronger in-region resiliency than a region without them, provided the workload and services are configured correctly.

For production applications, prefer candidate regions that support availability zones, especially when the workload requires high availability. Then verify that the specific services used by the workload support availability zones in that region.

Important distinction:

- A region supporting availability zones does not mean every service in that region supports availability zones.
- A service supporting availability zones does not mean your resource is automatically zone resilient.
- A zonal resource is placed in a specific zone and might require you to deploy multiple instances across zones.
- A zone-redundant resource is distributed across zones by the service, when supported and configured.
- A regional or nonzonal resource might be affected by a zone outage if Azure placed it in the affected zone.

Recommended production pattern:

- Deploy stateless compute across at least two or three zones when the service supports it.
- Use zone-redundant data services when available and appropriate.
- Place load balancers, gateways, and ingress components in zone-resilient configurations.
- Avoid single-zone dependencies in the critical path unless the risk is explicitly accepted.
- Test failure modes where one zone becomes unavailable or degraded.

Availability zones improve resilience against zone-level failures but do not protect against a full regional outage. If the workload cannot tolerate a full regional outage, design a multi-region architecture.

### 7. Decide whether one region is enough

A single-region architecture can be appropriate for many applications, especially early-stage, internal, low-criticality, or region-constrained workloads. However, a single region creates a dependency on that region's availability and capacity.

Use a single region when:

- The business can tolerate a regional outage or extended recovery time.
- Data residency prevents cross-region replication.
- The application is not mission critical.
- The cost and operational complexity of multi-region deployment outweigh the benefit.
- Backup and restore procedures meet the recovery objectives.
- Availability zones provide sufficient in-region resiliency.

Use multiple regions when:

- The workload has strict RTO or RPO requirements.
- The application is customer-facing and revenue-critical.
- Users are geographically distributed and latency matters.
- Regulatory boundaries require regionalized deployments.
- The workload needs protection from full regional outages.
- Capacity or quota constraints in one region create business risk.
- You need regional failover, active-active routing, or regional isolation.

Recommendation: Even if the initial deployment is single-region, make an explicit disaster recovery decision. Document what happens if the region is unavailable for several hours or longer. A single-region choice is acceptable when intentional; it is risky when accidental.

### 8. Choose a secondary region deliberately

If the workload needs a secondary region, do not automatically choose the paired region without evaluating the workload requirements. Azure region pairs can be useful because some Azure services use them for geo-replication, geo-redundancy, update sequencing, and disaster recovery behavior. However, many newer regions are nonpaired, and many services support geo-redundancy across nonpaired regions.

When selecting a secondary region, evaluate:

- Whether it is inside the same required data residency boundary.
- Whether all required services and SKUs are available there.
- Whether the primary and secondary regions are far enough apart to reduce shared disaster risk.
- Whether the regions are close enough for the application's replication and latency requirements.
- Whether the data replication technology supports the selected pair of regions.
- Whether the failover path is supported and tested.
- Whether both regions have enough quota and capacity.
- Whether users can be routed to either region.
- Whether operations teams can monitor, patch, deploy, and recover both regions.
- Whether the secondary region is active-active, active-passive warm standby, active-passive cold standby, or backup-only.

Do not assume paired regions automatically provide high availability. Deploying resources to a region's pair does not automatically make the workload resilient. You still need a workload-specific high availability and disaster recovery design.

### 9. Evaluate regional capacity and quota risk

Azure regions have quotas, capacity limits, and SKU-specific availability. A new application can fail to launch on time if the selected region cannot provide enough capacity for the chosen services.

Capacity risk is especially important for:

- Large VM deployments.
- Specialized VM families.
- GPU workloads.
- AI model deployments.
- High-throughput databases.
- Large Kubernetes clusters.
- Massive storage ingestion.
- Event streaming platforms.
- Regional failover environments that need to absorb production load.

Before launch:

- Confirm subscription quotas for the candidate region.
- Confirm service-specific quotas.
- Request quota increases early.
- Validate capacity for required SKUs.
- Avoid architectures that can only run on one scarce SKU unless the business accepts the risk.
- Confirm that the disaster recovery region can handle failover capacity, not just a token deployment.

Recommendation: Treat quota and capacity as launch dependencies. Do not wait until production deployment to discover regional constraints.

### 10. Compare regional cost

Azure pricing can vary by region. Cost should be part of region selection, but it should usually come after compliance, service availability, latency, reliability, and capacity.

Compare:

- Compute prices.
- Storage prices.
- Database prices.
- Network egress charges.
- Inter-region data transfer.
- Zone-related data transfer, if applicable for the service.
- Backup and replication costs.
- Monitoring and logging ingestion costs.
- Cost of running secondary regions.
- Cost of reserved capacity, savings plans, or commitments by region.

Do not pick a cheaper region if it materially worsens user latency, violates data residency, lacks required services, or weakens reliability below the business requirement.

Recommendation: Compare total cost of ownership, not only resource unit price. A lower-cost region can become more expensive if it adds latency workarounds, cross-region data transfer, duplicated services, support burden, or compliance complications.

### 11. Validate networking and connectivity

Region selection affects network design. Consider how the application connects to users, administrators, other Azure workloads, on-premises systems, partner APIs, and security inspection points.

Evaluate:

- ExpressRoute or VPN availability and routing.
- Private Link and private endpoint design.
- Hub-and-spoke network topology.
- Azure Firewall or network virtual appliance placement.
- DNS resolution and private DNS zones.
- Cross-region virtual network peering.
- Global routing with Azure Front Door, Traffic Manager, or other ingress services.
- Dependency on central identity, logging, or management services.
- Network latency from the region to on-premises datacenters.
- Data transfer costs between regions or geographies.

Recommendation: Avoid placing compute in one region while most data, identity, and network inspection dependencies live in another region unless the latency, cost, and failure modes are understood.

### 12. Consider operations, governance, and landing zones

The best technical region can still be a poor choice if the organization cannot operate it well.

Check whether the candidate region is supported by:

- Existing Azure landing zones.
- Azure Policy assignments.
- Management groups and subscription design.
- Log Analytics workspaces.
- Microsoft Sentinel or security monitoring.
- Backup vaults and recovery vaults.
- Key management and encryption standards.
- Private DNS and networking patterns.
- CI/CD pipelines and deployment approvals.
- Incident response procedures.
- Support coverage and escalation paths.
- Cost management and tagging policies.

Recommendation: If the organization has approved regions, start with those. If the workload needs a new region, treat onboarding that region as a platform task with governance, security, networking, monitoring, and support readiness.

## Recommended region-selection scoring model

After removing regions that fail mandatory requirements, score the remaining candidates. Adjust weights based on workload type.

| Category | Suggested weight | What good looks like |
| --- | ---: | --- |
| Compliance and data residency | Mandatory gate | Region is inside the required geography and satisfies regulatory, contractual, and sovereignty needs. |
| Required service availability | Mandatory gate | All required services, SKUs, tiers, and features are available. |
| Availability zone support | 20% | Region supports availability zones, and critical services support zone-resilient deployment. |
| User latency | 20% | Region is close to primary users and meets response-time goals under realistic tests. |
| Dependency latency | 10% | Region has acceptable latency to databases, identity, on-premises systems, APIs, and other dependencies. |
| Disaster recovery fit | 15% | Region works with the selected secondary region and recovery design. |
| Capacity and quota | 15% | Region has enough quota and realistic capacity for launch, growth, and failover. |
| Cost | 10% | Total cost is acceptable, including replication, network, backup, and secondary region costs. |
| Operational readiness | 10% | Platform, security, monitoring, deployment, and support processes are ready for the region. |

Example scoring table:

| Candidate region | Compliance gate | Service gate | Zones | Latency | DR fit | Capacity | Cost | Ops fit | Decision |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| East US 2 | Pass | Pass | 5 | 5 | 4 | 4 | 4 | 5 | Strong candidate |
| Central US | Pass | Pass | 5 | 4 | 4 | 3 | 4 | 4 | Good candidate |
| West US 3 | Pass | Partial | 5 | 3 | 4 | 3 | 4 | 3 | Blocked until service gap resolved |

Use numbers only after the mandatory gates are passed. A region with the best latency score is still not viable if it fails compliance or lacks a required service.

## Common architecture patterns

### Pattern 1: Single region with availability zones

Best for:

- Regional applications.
- Internal business applications.
- Production workloads that need high availability but can tolerate full-region recovery.
- Workloads constrained to one geography or country.

Recommended design:

- Use a region with availability zones.
- Deploy compute across zones.
- Use zone-redundant databases, storage, gateways, and load balancers where supported.
- Keep backups in a way that satisfies recovery requirements.
- Create a runbook for regional outage recovery.

Main risk:

- A full regional outage can still interrupt the application.

### Pattern 2: Active-passive multi-region

Best for:

- Business-critical applications that need regional disaster recovery but do not need both regions active all the time.
- Applications where data consistency, cost, or operational simplicity makes active-active difficult.

Recommended design:

- Run production in the primary region.
- Maintain a warm or cold standby in the secondary region.
- Replicate data based on RPO requirements.
- Automate infrastructure deployment to the secondary region.
- Test failover and failback.
- Confirm the secondary region has enough quota for real failover.

Main risk:

- If failover is not tested, the secondary region might not work when needed.

### Pattern 3: Active-active multi-region

Best for:

- Global applications.
- Very high availability requirements.
- Low-latency user experiences across continents.
- Workloads designed for distributed data and conflict handling.

Recommended design:

- Run the application in multiple regions simultaneously.
- Use global routing to direct users to the best healthy region.
- Design data replication, consistency, conflict resolution, and identity flows explicitly.
- Keep each region independently deployable and observable.
- Test regional isolation and partial failures.

Main risk:

- Active-active architecture is complex. Data consistency, deployment coordination, operational overhead, and cost are significantly higher.

### Pattern 4: Regionalized deployments by residency boundary

Best for:

- SaaS applications serving customers in multiple regulatory boundaries.
- Applications requiring customer data to stay in a specific geography.
- Enterprises that need regional isolation by market.

Recommended design:

- Deploy separate regional stamps for each required geography.
- Keep customer data in the assigned regional stamp.
- Use global control-plane services carefully, ensuring metadata and telemetry meet requirements.
- Automate provisioning so each regional stamp is consistent.
- Maintain region-specific compliance evidence.

Main risk:

- Operational duplication and inconsistent regional configuration if automation is weak.

## Specific recommendations by decision factor

### Data residency and compliance

Recommendations:

- Start with the legal and contractual data boundary.
- Confirm both application data and metadata requirements.
- Validate managed service behavior, not just compute location.
- Consider logs, backups, telemetry, support data, diagnostic data, and replicated data.
- If using a secondary region, ensure replication stays inside the allowed boundary.
- Use Azure Policy to restrict deployments to approved regions.
- Document the approved regions and the justification.

Questions to answer:

- What data is stored, processed, cached, logged, backed up, or replicated?
- Which data is customer data, personal data, confidential data, or regulated data?
- Are there country-specific requirements or only geography-level requirements?
- Are there industry-specific certifications required for the selected services?
- Are sovereign cloud regions required?
- Does the organization have an approved region list?

### Latency and performance

Recommendations:

- Place latency-sensitive workloads near users or near the most latency-sensitive dependency.
- Use Azure Front Door, CDN, or edge caching for global content distribution where appropriate.
- Avoid unnecessary cross-region calls in the synchronous request path.
- Measure application-level latency, not only network ping time.
- Test with expected authentication, TLS, DNS, database, and API call patterns.

Questions to answer:

- Where are the highest-volume users?
- Where are the most latency-sensitive users?
- Where are the dependent systems?
- Does the application make many chatty calls to a database or API in another region?
- Can static or read-heavy content be cached closer to users?
- Is the application tolerant of higher latency for some operations?

### Availability zones

Recommendations:

- Prefer regions with availability zones for production.
- Confirm zone support per service and per SKU.
- Use zone-redundant options for managed data services when they meet the workload needs.
- Deploy zonal compute across multiple zones, not only one.
- Avoid single-zone bottlenecks in ingress, secrets, data, or job orchestration.
- Test zone failure assumptions.

Questions to answer:

- Does the region support availability zones?
- Do all critical services support availability zones in that region?
- Are critical services zonal, zone-redundant, or only regional?
- Is zone redundancy automatic or configuration-based?
- Does the selected SKU support zone redundancy?
- What happens if one zone is unavailable?

### Disaster recovery

Recommendations:

- Define RTO and RPO before choosing the secondary region.
- Decide whether the secondary region is backup-only, cold standby, warm standby, hot standby, or active-active.
- Do not rely on region pairing alone as the disaster recovery plan.
- Confirm service-specific replication and failover behavior.
- Test failover with real dependencies, identity, DNS, secrets, certificates, and network paths.
- Include failback in the design.

Questions to answer:

- What outage duration can the business tolerate?
- How much data loss can the business tolerate?
- Does failover require manual approval?
- How will users be routed after failover?
- How will DNS, certificates, secrets, and managed identities work?
- Does the secondary region have enough capacity?
- How often will failover be tested?

### Service, SKU, and feature availability

Recommendations:

- Build a service-by-service region compatibility matrix.
- Validate planned SKUs, not only product names.
- Include preview features and specialized services.
- Confirm marketplace products and third-party dependencies.
- Confirm service limits and quotas.
- Keep evidence links or screenshots for architecture review.

Questions to answer:

- Are all required services available?
- Are all required SKUs and tiers available?
- Are required features generally available in that region?
- Is the service available in the organization's cloud environment, such as public Azure, Azure Government, or Azure operated by 21Vianet?
- Is there a regional dependency that could force data outside the desired geography?

### Capacity and scale

Recommendations:

- Request quotas early for the primary and secondary regions.
- Validate capacity for specialized compute and AI workloads.
- Consider regional capacity as part of business continuity.
- Design for SKU flexibility where possible.
- Monitor quota usage continuously.

Questions to answer:

- What capacity is needed at launch?
- What capacity is needed during peak load?
- What capacity is needed if another region fails over into this region?
- Are required SKUs constrained?
- How long do quota increases typically take for the required services?

### Cost

Recommendations:

- Use regional cost comparison after mandatory requirements are met.
- Include networking, replication, backup, logging, and secondary region costs.
- Evaluate commitment options by region.
- Consider operational cost, not only infrastructure cost.
- Avoid cost optimization that breaks recovery, compliance, or performance goals.

Questions to answer:

- Are resource prices different across candidate regions?
- Will the application pay more for cross-region data transfer?
- How much will logs and telemetry cost in the selected architecture?
- What is the cost of standby capacity?
- Are reservations or savings plans region-specific for the selected services?

### Security and governance

Recommendations:

- Confirm the region is allowed by policy.
- Use policy to prevent accidental deployment to nonapproved regions.
- Confirm encryption, key management, private networking, and logging patterns are supported.
- Keep secrets, keys, and certificates regionally available for failover.
- Include regional assumptions in threat modeling.

Questions to answer:

- Can developers deploy to only approved regions?
- Are key vaults, managed identities, private endpoints, and logging available in the design?
- Are backups protected and regionally appropriate?
- Does the secondary region have access to required keys and secrets?
- Does incident response cover the selected region?

## Anti-patterns to avoid

Avoid these common mistakes:

- Choosing a region because it is the default in a tutorial.
- Choosing the closest region to the development team instead of the users.
- Assuming all Azure services are available in all regions.
- Assuming availability zones are available for every service in a zone-capable region.
- Assuming a paired region automatically provides disaster recovery.
- Forgetting that logs, backups, telemetry, and metadata can have residency implications.
- Designing a multi-region app without testing failover.
- Choosing a secondary region without confirming quota and capacity.
- Placing compute and data in different regions without a strong reason.
- Using a region with scarce capacity for a workload that must scale quickly.
- Ignoring network egress and inter-region transfer costs.
- Treating region selection as irreversible, but failing to automate deployment portability.
- Using active-active architecture when the team cannot operate it.
- Selecting a region before confirming service features and SKUs.

## Example recommendations

### Example 1: US customer-facing web application

Likely approach:

- Shortlist US regions that support availability zones.
- Prefer a region close to the largest user base and existing dependencies.
- Validate required services and SKUs.
- Use zone-resilient architecture in the primary region.
- Select a secondary US region for disaster recovery if RTO and RPO require it.
- Use global ingress if users are spread across the country.

Reasoning:

The main tradeoff is likely latency, zone support, service availability, and disaster recovery. Data residency is probably satisfied by multiple US regions, but the team should still confirm contractual requirements.

### Example 2: EU SaaS application with customer data residency commitments

Likely approach:

- Limit candidates to allowed European regions.
- Prefer regions with availability zones.
- Confirm all customer data, backups, logs, and replicas stay within the allowed geography.
- Use a second European region for disaster recovery if required.
- Consider regional stamps if customers require stricter country-level separation.

Reasoning:

Data residency and compliance are primary. Latency and cost matter after the residency boundary is satisfied.

### Example 3: AI application requiring specialized model or GPU capacity

Likely approach:

- Start with model, GPU, or AI service availability, because these capabilities can be region-limited.
- Confirm quota and capacity before committing.
- Evaluate latency to users and data sources.
- Design fallback behavior if capacity is constrained.
- Consider multiple regions if the application is business critical and the AI service supports the required deployment model across regions.

Reasoning:

For AI workloads, the "best" region is often constrained by service availability, quota, capacity, model support, and data residency. Do not assume the closest region can host the required AI capability.

### Example 4: Internal enterprise application connected to on-premises systems

Likely approach:

- Choose a region with strong connectivity to the organization's network hubs.
- Validate ExpressRoute or VPN routing.
- Keep application and data close to the systems they call most often.
- Use availability zones for production.
- Align with existing landing zone, monitoring, and security patterns.

Reasoning:

For internal apps, dependency latency and operational fit can matter more than public user proximity.

## Region decision record template

Use this template to document the final decision.

```markdown
# Azure Region Decision Record

## Application

- Name:
- Owner:
- Environment:
- Date:

## Decision

- Primary region:
- Secondary region, if any:
- Deployment pattern: single-region / active-passive / active-active / regional stamps

## Mandatory requirements

- Data residency:
- Compliance:
- Required services:
- Required SKUs:
- Required RTO:
- Required RPO:
- Required availability target:

## Candidate regions evaluated

| Region | Result | Reason |
| --- | --- | --- |
|  |  |  |

## Why this region was selected

-

## Known tradeoffs

-

## Disaster recovery plan

-

## Capacity and quota evidence

-

## Service availability evidence

-

## Review triggers

- New geography or customer residency requirement.
- New required Azure service or SKU.
- Significant scale increase.
- Change in RTO or RPO.
- Repeated capacity constraints.
- Major cost change.
```

## Final checklist

Before approving the region decision, confirm:

- The selected region is inside the required data residency boundary.
- The selected region satisfies regulatory, contractual, and sovereignty requirements.
- The selected region is allowed by organizational policy.
- All required Azure services are available in the region.
- All required SKUs, tiers, models, and features are available in the region.
- Critical services support availability zones or the design explicitly accepts the risk.
- The application architecture uses availability zones correctly where available.
- Expected user latency has been measured or reasonably estimated.
- Dependency latency has been evaluated.
- Quotas are sufficient for launch.
- Capacity risk has been assessed for specialized services.
- Regional cost has been estimated.
- Networking, DNS, ingress, private connectivity, and security inspection are feasible.
- Logs, backups, telemetry, and replicated data meet residency requirements.
- The disaster recovery strategy is documented.
- The secondary region, if any, has been validated for services, capacity, quota, and compliance.
- Failover and restore procedures are testable.
- Operations, monitoring, support, and incident response are ready for the region.
- The decision has been documented with evidence.

## Recommended source references

- [Select Azure regions](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-setup-guide/regions)
- [What are Azure regions?](https://learn.microsoft.com/azure/reliability/regions-overview)
- [Azure regions list](https://learn.microsoft.com/azure/reliability/regions-list)
- [What are availability zones?](https://learn.microsoft.com/azure/reliability/availability-zones-overview)
- [Azure region pairs and nonpaired regions](https://learn.microsoft.com/azure/reliability/regions-paired)
- [Azure products available by region](https://azure.microsoft.com/explore/global-infrastructure/products-by-region/)
- [Azure network round-trip latency statistics](https://learn.microsoft.com/azure/networking/azure-network-latency)
- [Azure subscription and service limits, quotas, and constraints](https://learn.microsoft.com/azure/azure-resource-manager/management/azure-subscription-service-limits)
- [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/)

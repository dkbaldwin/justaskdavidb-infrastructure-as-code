### Add EC2 Instance Support for Fargate-Only Deployment

**Problem/Issue:**
The 'InstanceType' and 'LatestAmiId' parameters (lines 5-16) are defined but are currently unused in the template, since this deployment is Fargate-only. This may confuse users.

**Spike:**
Investigate whether introducing EC2 instance creation into the template offers value. Clarify how an on-demand EC2 instance can be incorporated into a primarily Fargate-based deployment and specify usage scenarios.

**Proposed Solution:**
Add support for creating a start/stop on-demand EC2 instance using these parameters or, alternatively, remove them if they cannot be used effectively.

**Justification:**
Improves transparency and usability of the template by either leveraging defined parameters or removing unused ones.

**Date Raised:** 2025-12-07 11:13:17
**Raised By:** dkbaldwin
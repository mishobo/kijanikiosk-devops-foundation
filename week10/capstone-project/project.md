[Early Intro] Capstone Project Submission Guide
Capstone Project: KijaniKiosk End-to-End Delivery
Ten weeks ago, KijaniKiosk had no pipeline, no Infrastructure as Code, no containers, and no observability. You have built all of it, week by week, using the same codebase, the same personas, and the same production standards.

The capstone is the final question: can you take what you have built and extend it into something that meets a production engineering bar? Not a polished demo built overnight, but a system that reflects deliberate design choices, honest assessment of its own gaps, and the kind of documentation that makes it transferable to another engineer.

Nia's final requirement: "When this is done, I want to be able to hand the repository to a new engineer on the team and have them contribute meaningfully within a day. That is the standard."


Choose Your Track
Both tracks build on the same KijaniKiosk codebase. Both are assessed on the same rubric. Choose the track that lets you demonstrate the most depth in the areas you care about most.

Track A: Infrastructure-First
You extend the KijaniKiosk deployment into a multi-environment, monitored, production-approaching system. This track is for learners who want to go deep on IaC, pipeline automation, and observability.

Required components:

A kijani-staging namespace provisioned by Terraform and configured by Ansible, isolated from the default production namespace.
A Jenkins pipeline that deploys to staging automatically on merge to main, runs a smoke test against the staging deployment, and only offers the production approval gate after the smoke test passes.
kk-payments running in staging with environment-specific ConfigMaps (different DB_HOST from production) and the same Deployment manifest used for both environments.
At least one monitoring signal for kk-payments committed to the repository. Option A: a Prometheus alert rule (prometheus.io/docs/prometheus/latest/configuration/alerting_rules) that fires when error rate exceeds 5% for 2 minutes. Option B: a log-based error rate calculation following the Week 7 SLO pattern, reading from kk-payments structured logs and outputting a summary to a monitoring file. Both options demonstrate the same observability principle. Option A requires Prometheus installed; Option B requires only the existing structured logging.
The Week 10 serverless receipt chain integrated: kk-payments in the staging environment writes to the kk-payments-receipts-staging bucket and the receipt chain fires correctly.
Track B: Serverless-First
You extend the Week 10 serverless receipt chain into a complete production-approaching system with a fourth function, a real cloud deployment, and documented governance. This track is for learners who want to go deep on serverless architecture, event-driven design, and AI governance.

Required components:

A fourth function, kk-analytics, triggered by kk-notifier's output bucket, that aggregates receipt events (count, total amount, timestamp range) and logs a structured summary.
The full four-function stack deployed using serverless deploy --stage staging. Preferred: deploy to a real cloud provider (AWS free tier, Google Cloud Functions free tier, or Cloudflare Workers free tier) with serverless info output as confirmation. Acceptable alternative: deploy using serverless-offline in production-mode configuration and use serverless print --format yaml as verification output. Cloud deployment demonstrates the full production path; the local alternative is assessed at Proficient rather than Exemplary for this component.
The Thursday governance checklist applied to the deployed stack: all six controls assessed against the actual deployed configuration, not against a local mock, with documented findings and remediations.
The kk-payments Kubernetes deployment (from Week 9) writing receipt events to the production S3 bucket that triggers the chain. The connection between the Kubernetes layer and the serverless layer is the integration seam to demonstrate.
A Jenkins pipeline update that deploys the serverless stack to staging as part of the pipeline, with the approval gate before the production serverless deploy stage.

What to Submit
All six deliverables are required for both tracks. Partial submissions are assessed on the rubric at their actual completion state.

#	Deliverable	Format	
1	Project scope document: problem statement, track, in-scope components, out-of-scope items, success criteria, architecture diagram	1 page PDF + PNG diagram	
2	Working repository: structured according to CAP-3 conventions, README complete, all track components implemented and functional	GitHub repository link	
3	Pipeline demonstration: CI/CD pipeline running end-to-end with approval gate visible, at least one deploy to staging and one to production shown	Loom video (max 5 minutes narrated; up to 8 minutes total including automated pipeline stages) or screenshot sequence	
4	Peer feedback log: at least three issues documented with severity and resolution, at least one resolved improvement committed with a GitHub Issue reference	GitHub Issues link or PDF log	
5	Slide deck: 6-10 slides covering the six required sections from Page 6	PDF	
6	Reflection document: one page answering the three required questions from Page 6 with specific, honest responses	PDF or Markdown in repository	

Timeline and Support
Session	Recommended focus
Capstone Session 1	Scope document and architecture diagram complete. Track chosen. Repository created with initial directory structure.
Capstone Session 2	Infrastructure layer complete and reproducible. Delivery layer started.
Capstone Session 3	Delivery and runtime layers complete. Intelligence layer started. README first draft.
Capstone Session 4	Peer review session. Feedback log started. At least one improvement committed.
Capstone Session 5	Slide deck complete. Demo rehearsed twice. Release tag created. All deliverables assembled.
Presentation Day	Live demo and slide presentation. Reflection written after demo. Final submission uploaded.
Where to find the grading criteria
The full 8-dimension rubric and grade boundaries appear on the Capstone Project Submission assignment page. Review it before starting your capstone work: the rubric specifies what is required at each level (Developing / Approaching / Proficient / Exemplary) and what the non-negotiable requirements are for academic integrity.

Submission deadline: End of Presentation Day session. The reflection document may be submitted up to 24 hours after the live presentation.


-------------------------------------------

[Early Intro] Capstone Project Submission
Due No due date Points 100 Submitting a website url
Capstone Project: KijaniKiosk End-to-End Delivery
Ten weeks ago, KijaniKiosk had no pipeline, no Infrastructure as Code, no containers, and no observability. You have built all of it, week by week, using the same codebase, the same personas, and the same production standards.

The capstone is the final question: can you take what you have built and extend it into something that meets a production engineering bar? Not a polished demo built overnight, but a system that reflects deliberate design choices, honest assessment of its own gaps, and the kind of documentation that makes it transferable to another engineer.

Nia's final requirement: "When this is done, I want to be able to hand the repository to a new engineer on the team and have them contribute meaningfully within a day. That is the standard."


Choose Your Track
Both tracks build on the same KijaniKiosk codebase. Both are assessed on the same rubric. Choose the track that lets you demonstrate the most depth in the areas you care about most.

Track A: Infrastructure-First
You extend the KijaniKiosk deployment into a multi-environment, monitored, production-approaching system. This track is for learners who want to go deep on IaC, pipeline automation, and observability.

Required components:

A kijani-staging namespace provisioned by Terraform and configured by Ansible, isolated from the default production namespace.
A Jenkins pipeline that deploys to staging automatically on merge to main, runs a smoke test against the staging deployment, and only offers the production approval gate after the smoke test passes.
kk-payments running in staging with environment-specific ConfigMaps (different DB_HOST from production) and the same Deployment manifest used for both environments.
At least one Prometheus alert rule that fires on a meaningful kk-payments health signal (error rate, latency, or pod restart count). Alert configuration committed to the repository.
The Week 10 serverless receipt chain integrated: kk-payments in the staging environment writes to the kk-payments-receipts-staging bucket and the receipt chain fires correctly.
Track B: Serverless-First
You extend the Week 10 serverless receipt chain into a complete production-approaching system with a fourth function, a real cloud deployment, and documented governance. This track is for learners who want to go deep on serverless architecture, event-driven design, and AI governance.

Required components:

A fourth function, kk-analytics, triggered by kk-notifier's output bucket, that aggregates receipt events (count, total amount, timestamp range) and logs a structured summary.
The full four-function stack deployed to a real cloud provider using serverless deploy --stage staging. Local development confirmed with serverless-offline; production deployment confirmed with serverless info output.
The Thursday governance checklist applied to the deployed stack: all six controls assessed against the actual deployed configuration, not against a local mock, with documented findings and remediations.
The kk-payments Kubernetes deployment (from Week 9) writing receipt events to the production S3 bucket that triggers the chain. The connection between the Kubernetes layer and the serverless layer is the integration seam to demonstrate.
A Jenkins pipeline update that deploys the serverless stack to staging as part of the pipeline, with the approval gate before the production serverless deploy stage.

What to Submit
All six deliverables are required for both tracks. Partial submissions are assessed on the rubric at their actual completion state.

#	Deliverable	Format	Skills map
1	Project scope document: problem statement, track, in-scope components, out-of-scope items, success criteria, architecture diagram	1 page PDF + PNG diagram	CAP-1
2	Working repository: structured according to CAP-3 conventions, README complete, all track components implemented and functional	GitHub repository link	CAP-2, CAP-3
3	Pipeline demonstration: CI/CD pipeline running end-to-end with approval gate visible, at least one deploy to staging and one to production shown	Loom video (max 5 minutes) or screenshot sequence	CAP-2
4	Peer feedback log: at least three issues documented with severity and resolution, at least one resolved improvement committed with a GitHub Issue reference	GitHub Issues link or PDF log	CAP-5
5	Slide deck: 6-10 slides covering the six required sections from Page 6	PDF	CAP-6
6	Reflection document: one page answering the three required questions from Page 6 with specific, honest responses	PDF or Markdown in repository	CAP-6

Timeline and Support
Session	Recommended focus
Capstone Session 1	Scope document and architecture diagram complete. Track chosen. Repository created with initial directory structure.
Capstone Session 2	Infrastructure layer complete and reproducible. Delivery layer started.
Capstone Session 3	Delivery and runtime layers complete. Intelligence layer started. README first draft.
Capstone Session 4	Peer review session. Feedback log started. At least one improvement committed.
Capstone Session 5	Slide deck complete. Demo rehearsed twice. Release tag created. All deliverables assembled.
Presentation Day	Live demo and slide presentation. Reflection written after demo. Final submission uploaded.
Submission deadline: End of Presentation Day session. The reflection document may be submitted up to 24 hours after the live presentation.

Score Summary
Dimension	CAP	Max Points	Score
1. Project Scope and Planning	CAP-1	10	 
2. Pipeline Completeness and Automation	CAP-2	20	 
3. AI Tooling Integration and Governance	CAP-2 + Week 10	10	 
4. Repository Structure and Documentation	CAP-3	15	 
5. Version Control Hygiene	CAP-4	10	 
6. Testing and Feedback Integration	CAP-5	15	 
7. Presentation and Live Demo	CAP-6	10	 
8. Reflection Quality	CAP-6	10	 
Total	100	 
Grade boundaries: 90-100 = Distinction | 75-89 = Merit | 60-74 = Pass | Below 60 = Resubmission required

Resubmission: One resubmission permitted within 5 working days of results. Maximum grade on resubmission: 75 (Merit ceiling). Resubmission must address all dimensions scoring below 5.

Academic integrity: All submitted code must be the learner's own work. AI-generated code is permitted subject to the documentation requirements in Dimension 3. Undisclosed AI-generated code (code not documented in the governance log) constitutes an academic integrity violation.

Rubric
Capstone Project Rubric
Capstone Project Rubric
Criteria	Ratings	Pts
This criterion is linked to a learning outcomeDimension 1: Project Scope and Planning (CAP-1)
10 Pts
Exemplary
Scope document is one page. Problem statement names a specific, verifiable operational gap. In-scope items are five or fewer, each in one sentence. Out-of-scope items list at least two exclusions with reasons. Success criteria are measurable and each is directly demonstrable in the live demo. Architecture diagram shows all components and labels every connection with what flows across it.
8 Pts
Proficient
Scope document addresses all five questions. Problem statement is specific but one success criterion is vague or not directly demonstrable. Architecture diagram is present and mostly complete with minor unlabelled connections.
6 Pts
Developing
Scope document is present but problem statement is generic ("improve the system") or success criteria cannot be verified in a demo. Architecture diagram is incomplete or does not match the actual system built.
4 Pts
Beginning
Scope document is missing, is less than half a page, or does not address the problem statement and success criteria. No architecture diagram submitted.
10 pts
This criterion is linked to a learning outcomeDimension 2: Pipeline Completeness and Automation (CAP-2)
20 Pts
Exemplary
All four layers (infrastructure, delivery, runtime, intelligence) are present and working. Infrastructure is reproducible from a clean checkout. A merge to main triggers the pipeline without manual steps. The approval gate functions correctly and records an approval reason. The application is running with structured logs, probes, resource limits, and configuration separation. A deliberate fault is introduced and handled gracefully in the demo. (Track A: staging pipeline with smoke test demonstrated. Track B: serverless stack deployed to real cloud provider demonstrated.)
17 Pts
Proficient
Three of four layers are complete and working. The pipeline runs but one stage requires a manual step not in the README, or the approval gate is present but does not capture an approval reason. The fault handling demo is missing but the happy path works correctly.
13 Pts
Developing
Two layers are complete. Pipeline runs but significant manual steps are required that are not documented. Application is deployed but missing probes, resource limits, or configuration separation. The track-specific requirement (staging environment or cloud deployment) is absent or non-functional.
8 Pts
Beginning
Fewer than two layers working. Pipeline does not run or requires extensive undocumented manual intervention. Application cannot be demonstrated as running in the target environment.
20 pts
This criterion is linked to a learning outcomeDimension 3: AI Tooling Integration and Governance (CAP-2 + Week 10)
10 Pts
Exemplary
docs/ai-governance-log.md contains at least two entries in the Week 10 eight-field format (defined on Page 2 of the capstone guide). Each entry names what the AI produced, what it got wrong, and what specific change the reviewer made. The "what it got wrong" field is never empty or "nothing". At least one governance checklist item (from the six-point list) is explicitly referenced in the log. The slide deck AI tooling slide matches the log entries.
8 Pts
Proficient
Governance log contains at least one entry with most eight fields completed. The "what it got wrong" field has a response but it is vague ("could be improved"). The slide deck references AI tooling use.
6 Pts
Developing
Governance log exists but has fewer than the required fields, or "what it got wrong" is empty or states "the AI was entirely correct" with no manual verification described. AI tooling was used but not documented in the governance format.
4 Pts
Beginning
No governance log submitted. No evidence of AI tooling use. Or governance log submitted but describes tool use without any critical assessment of the AI output.
10 pts
This criterion is linked to a learning outcomeDimension 4: Repository Structure and Documentation (CAP-3)
15 Pts
Exemplary
Repository follows the track-appropriate directory structure. No unnamed or temp directories. All files follow naming conventions. README covers all seven required sections. Architecture diagram is present in docs/ and matches the actual system. A classmate can follow the README to a working system without asking questions. No secrets committed to any file. docs/ai-governance-log.md present.
12 Pts
Proficient
Directory structure is mostly correct with one or two files in the wrong location. README covers five or six of the seven sections. Architecture diagram present but does not match the current system state. One minor undocumented prerequisite in the setup steps.
9 Pts
Developing
README exists but is missing three or more required sections. Directory structure does not follow conventions: files at root level that belong in subdirectories, or temp directories present. Architecture diagram is missing or is the original scope diagram unchanged from a system that diverged during the build.
5 Pts
Beginning
No README, or README is a single paragraph with no structure. Repository is a flat list of files with no directory organisation. Secrets committed to the repository.
15 pts
This criterion is linked to a learning outcomeDimension 5: Version Control Hygiene (CAP-4)
10 Pts
Exemplary
All commits use the conventional commit format. No direct commits to main during development. At least two feature branches visible in the git history. At least one pull request with a meaningful description. At least 15 commits with informative messages spread across at least three separate calendar days (verifiable with git log --format="%ad %s" --date=short). Annotated release tag v1.0.0 created and pushed. No commit messages that are "fix", "update", "wip", or similar.
8 Pts
Proficient
Most commits use conventional format with two or three vague messages. One or two direct commits to main. At least one feature branch present. Release tag exists but is lightweight rather than annotated. Between 10 and 14 total commits.
6 Pts
Developing
Fewer than 10 commits, or most commits have vague messages ("fix", "update"). All commits directly to main. No feature branches. Release tag absent or created after the submission deadline.
4 Pts
Beginning
Fewer than five commits. No conventional commit format. No branching. Repository appears to have been committed in one or two large batches at the end of the project.
10 pts
This criterion is linked to a learning outcomeDimension 6: Testing and Feedback Integration (CAP-5)
15 Pts
Exemplary
Peer review session completed with a classmate. Feedback log contains at least three entries with issue, severity, resolution, and evidence (commit hash or screenshot). At least one GitHub Issue is closed with a commit reference (required for Exemplary; Developing level is awarded for a documented self-review). The improvement is visible in the repository: a before/after comparison is possible using the commit history. Test plan was written before the session and is included in the submission.
12 Pts
Proficient
Peer review session completed. Feedback log has at least three entries but resolution evidence is missing for one or two items. One improvement committed but the GitHub Issue is not linked to the commit. Test plan absent but the session itself is documented.
9 Pts
Developing
Self-review documented in place of a peer session. Feedback log has fewer than three entries. No improvement committed to the repository, or the improvement is committed but not connected to any feedback item. No test plan.
5 Pts
Beginning
No feedback log submitted. No evidence of any testing session, peer or self-directed. No improvements attributable to testing feedback.
15 pts
This criterion is linked to a learning outcomeDimension 7: Presentation and Live Demo (CAP-6)
10 Pts
Exemplary
Live demo shows the system working end-to-end including the approval gate and a fault handling scenario. Slide deck covers all six required sections. The Key Decision slide names a genuine technical trade-off (not a feature description). AI tooling slide entries match the governance log. Production gaps slide names specific components and specific remediations. Presenter can answer technical questions about any arrow in the architecture diagram.
8 Pts
Proficient
Live demo shows the happy path working. Fault handling not demonstrated but screenshot fallback is available. Slide deck present with five of six required sections. Key Decision slide describes a decision but does not clearly articulate the trade-off. Production gaps slide identifies gaps without naming specific remediations.
6 Pts
Developing
Live demo fails and no screenshot fallback is available, or demo runs but the approval gate is not shown. Slide deck has fewer than five required sections. No Key Decision slide. Production gaps slide says "more security" or similar without specifics.
4 Pts
Beginning
No live demo and no screenshot fallback. Slide deck not submitted or has fewer than four slides. Presenter cannot answer basic technical questions about their own architecture.
10 pts
This criterion is linked to a learning outcomeDimension 8: Reflection Quality (CAP-6)
10 Pts
Exemplary
Reflection document is one page. All three required questions are answered with specific, honest responses. "What did you get wrong" names a specific technical decision and explains why a different approach would have been better. "Most important thing learned" names one concept, the week it appeared, and what changed in thinking. "Second pass" names specific additions, removals, or changes, not general improvements. Reflection could not be written by someone who did not complete this specific project.
8 Pts
Proficient
All three questions answered. "What did you get wrong" names a specific decision. "Most important thing learned" identifies a concept but the explanation of what changed in thinking is vague. "Second pass" mentions specific areas but descriptions are general rather than component-specific.
6 Pts
Developing
Two of three required questions answered. "What did you get wrong" says everything went as planned, or identifies a problem without explaining what should have been done differently. Reflection reads like a project summary rather than a personal technical analysis.
4 Pts
Beginning
Reflection not submitted, or reflection is a list of features built with no personal analysis. Generic answers that could apply to any DevOps course without modification.
10 pts
Total points: 100


------------------------------------------------------------------------------------

Project Planning & Scoping
Ten weeks of KijaniKiosk work sits in your repository. You have a CI/CD pipeline, Terraform-provisioned infrastructure, a Kubernetes deployment with probes and Ingress, a serverless receipt chain, and a governance framework for AI-generated changes. The capstone asks one question: can you take everything you have built and extend it into something that genuinely demonstrates production-grade thinking, to an audience who has never seen your work before?

Before writing a single line of code for the capstone, you need a plan. This page covers how to scope a project that is honest about what it will and will not deliver, and how to write that scope in a way that holds up under technical scrutiny.


Why This Matters
Scope creep kills more engineering projects than technical failure does. A capstone that attempts to build everything ends up demonstrating nothing clearly. A senior DevOps engineer reviewing your work does not want to see the maximum number of tools: they want to see evidence that you understand what each tool is for and when not to use it.

Tendo put it directly at the start of Week 10: "If someone clones your repository, they should be able to reproduce the full system. Friday is your proof that you can." The capstone extends that standard: your scope document is the promise. Your repository is the proof. They must match.


What Good Looks Like
A strong capstone scope document is one page. It answers five questions precisely, without padding:

What problem are you solving? Name the specific operational gap in the KijaniKiosk system that your capstone addresses. Not "I will improve the infrastructure" but "kk-payments currently has no automated rollback on health check failure in the staging environment."
 

What will you build? Name the components, tools, and integrations. One sentence each. No vague phrases like "production-grade security".
 

What is explicitly out of scope? This is as important as what is in scope. Naming what you are not building demonstrates that you made deliberate choices, not accidental omissions.
 

How will you know it worked? State two or three measurable success criteria. Not "the pipeline works" but "kubectl rollout status returns exit 0 after every merge to main" or "all three serverless functions log structured JSON with correlation IDs traceable to a single curl."
 

What does the system look like? An architecture diagram showing every component and the data or event flows between them. Hand-drawn is acceptable. An unreadable diagram is not. If hand-drawn, scan at sufficient resolution to read all labels at 100% zoom. draw.io (draw.io) and Excalidraw (excalidraw.com) are free, browser-based tools recommended for diagrams that will be reused in the README and slide deck.

How to Do It
Step 1: Choose your track. Review the two capstone tracks in the Capstone Project Submission Guide. Choose the one that builds on the weeks you feel most confident about. You are not choosing the easier one: you are choosing the one where you can go deepest rather than broadest.

 

Step 2: Identify the specific gap. Look at your Week 10 Friday project submission. Find Nia's production readiness gap analysis that you wrote. One of those gaps is your capstone problem statement. The capstone is not a new system: it is a production-grade extension of the system you already built.

 

Step 3: Write the scope document. Write it in Markdown and export to PDF using Pandoc (pandoc scope.md -o scope.pdf) or a Markdown-to-PDF converter such as a browser print-to-PDF from a Markdown preview. You can also write directly in a word processor and export to PDF. Use this structure:

# Capstone Scope Document

## Problem Statement
One paragraph. What is broken or missing. Why it matters for KijaniKiosk.

## Track
Track A (Infrastructure-first) or Track B (Serverless-first)

## What I Will Build
- Component 1: one sentence
- Component 2: one sentence
- Component 3: one sentence
(maximum five items)

## What Is Out of Scope
- Item 1 and why
- Item 2 and why

## Success Criteria
1. Measurable outcome 1
2. Measurable outcome 2
3. Measurable outcome 3 (optional)

## Architecture Diagram
[attached as PNG or embedded]
 

Step 4: Draw the architecture diagram. Every component your capstone touches must appear. Every connection must be labelled with what flows across it (HTTP request, S3 event, Terraform provision, kubectl apply). If you cannot draw it, you do not yet understand what you are building.

 

Step 5: Review against the success criteria. For each success criterion, ask: "Can I demonstrate this in a 5-minute live demo?" If the answer is no, either simplify the criterion or simplify the scope until it is yes.

 


KijaniKiosk Example: A Strong Problem Statement
Amina drafts this for her Track A capstone:

"kk-payments currently deploys to a single environment (default namespace on a local Minikube cluster). There is no staging environment. Engineers testing changes against the production configuration have no isolation. When a bad image tag is pushed, the rollback requires manual intervention. The capstone will provision a kijani-staging namespace using Terraform, configure it with the correct environment variables using Ansible, update the Jenkins pipeline to deploy to staging first with automated health validation before the production approval gate, and add a Prometheus alert that fires when kk-payments error rate exceeds 5% for more than 2 minutes.
Success criteria:
(1) a push to main triggers staging deployment automatically,
(2) the production gate requires explicit approval and shows the staging health check result,
(3) a deliberately introduced bad image tag triggers an automated rollback in staging before reaching production."
Notice what this does not say: "I will add security", "I will make it more reliable", "I will implement DevOps best practices". Every claim is specific, verifiable, and demonstrable in a five-minute demo.


Checklist Before Moving to Page 2
Track chosen (A or B) and recorded in the scope document.
Problem statement names a specific operational gap, not a general improvement.
In-scope items listed: five or fewer, one sentence each.
Out-of-scope items listed with a reason for each exclusion.
Two or three success criteria stated, each demonstrable in a live demo.
Architecture diagram complete and shows all components and flows.


----------------------------------------------------------------------------


Building a Complete AI-Powered DevOps Workflow
The scope document is approved. The architecture diagram is drawn. Now you build. This page covers the engineering discipline required to construct a complete, integrated DevOps workflow that holds together under scrutiny: not a collection of parts, but a system where each component was chosen deliberately and where the connections between components are as well-designed as the components themselves.


Why This Matters
A DevOps engineer who can configure each tool in isolation is a technician. A DevOps engineer who can design a system where Terraform provisions the infrastructure that Ansible configures, that Jenkins deploys to, that Kubernetes runs, that Prometheus monitors, and where a serverless function handles the async work that would otherwise block the main service: that engineer is employable at a senior level.

The capstone is your evidence for the second category. The test is not whether every component works in isolation: your weekly projects already proved that. The test is whether they work together, reliably, from a clean checkout, with the seams as clean as the components.


What Good Looks Like
A complete AI-powered DevOps workflow for the capstone has four layers, each built on the previous:

Layer	What it covers	Course foundation
Infrastructure	Environments exist and are reproducible. A fresh checkout plus one command creates the target environment.	Terraform (Week 4), Ansible (Week 4), serverless.yml resources block (Week 10)
Delivery	Code changes move from commit to deployed application automatically, with human approval before production.	Jenkins pipeline (Weeks 5, 7), input step (Week 10), kubectl rollout status gate
Runtime	The deployed application is production-approaching: probes, resource limits, configuration separation, rollback capability.	Kubernetes Deployments (Week 9), ConfigMaps and Secrets (Week 9), serverless functions (Week 10)
Intelligence	AI tooling augments at least one operational task, with documented governance and a human review step.	AI-assisted log analysis (Week 10), governance checklist (Week 10)
Your capstone must demonstrate all four layers. It does not need to be exhaustive at each layer: depth in one layer is more valuable than thin coverage across all four.


How to Do It
Build in layers, not in parallel
Complete each layer before starting the next. Infrastructure must be reproducible before you wire the delivery layer. The delivery layer must work before you configure the runtime layer. A system that is 50% built across four layers is undemonstrable. A system with two complete layers and two partial ones can be demoed cleanly while work continues.

 

Test the seams, not just the components
The failure modes in integrated systems almost always live at the connections between components, not inside the components themselves. After each layer, run an end-to-end test that exercises the connection to the previous layer:

After infrastructure: run serverless deploy --stage staging or kubectl apply -f k8s/ -n kijani-staging and confirm the target environment was created by the IaC, not pre-existing.
After delivery: push a commit and watch the pipeline run to completion without any manual steps other than the approval gate.
After runtime: send a request to the deployed application and verify logs appear with the correct structured format and correlation IDs.
After intelligence: run the AI tooling on a sample log and document the output in the governance format from Week 10.
 

AI integration requirements
The intelligence layer must show AI tooling being used for a genuine operational task, not as a demonstration. Acceptable uses: AI-assisted log analysis during a simulated incident; AI-generated infrastructure code with the governance checklist applied and documented; AI-generated pipeline configuration reviewed and corrected with specific changes noted; AI-assisted writing or review of the scope document or README, documented with what was suggested and what you changed before accepting it. The Week 10 AI use documentation format (eight fields, honest "what it got wrong" entry) is the required format for all governance log entries.

The eight-field AI governance log format
Every entry in docs/ai-governance-log.md must contain these eight fields:

Date
Tool used (Claude, ChatGPT, GitHub Copilot, etc.)
Task description (what you were trying to accomplish)
What was provided to the AI (the prompt or context given)
What the AI produced (summarise the output)
What it got right (specific correct elements)
What it got wrong (specific gaps, errors, or inappropriate suggestions)
What you changed before applying the output (the specific changes made)
Field 7 must never be empty. If you cannot identify anything the AI got wrong, you did not review it carefully enough. Run the output through the Week 10 six-point governance checklist: at least one control will identify a gap in any AI-generated infrastructure code.

The integration test that matters most: Delete everything. Run the setup commands from your README on a machine that has never seen your project. If the system comes up clean, you have built something reproducible. If it fails, the README is incomplete or the infrastructure is not fully declared. Fix the README and the IaC before the capstone submission: a system that requires undocumented manual steps is not production-grade.
What "delete everything" means on a local setup: run minikube delete (destroys the cluster), docker system prune -a (removes all images and build cache), and rm -rf /tmp/kijani-s3-local (removes local S3 data). Then run minikube start and follow your README from Step 1. If any step fails or requires prior knowledge, the README needs updating.


KijaniKiosk Example: The Integration Seam That Usually Breaks
In Track A, the most common failure point is the seam between the Ansible configuration step and the Kubernetes deployment step. Ansible configures the VM or namespace with the correct environment. Jenkins then applies the Kubernetes manifests. If the ConfigMap names in the Ansible output do not match the ConfigMap references in the Deployment manifests, the Pods fail with CreateContainerConfigError and the pipeline shows a successful deploy while the application is broken.

The fix is to define ConfigMap names in one place: a Terraform variable or an Ansible variable that both the Ansible role and the Kubernetes manifest generation step read from. The same DRY principle that applies to serverless.yml custom block applies here.

In Track B, the most common failure point is the S3 bucket name mismatch between the Serverless Framework deployment and the kk-payments write operation. The bucket name must be the same value in both places. Use an environment variable in kk-payments that reads from the same source as the ${self:custom.receiptsBucket} reference in serverless.yml.


Checklist Before Moving to Page 3
Infrastructure layer is reproducible from a clean checkout: one command creates the target environment.
Delivery layer: a commit triggers the pipeline without manual steps; approval gate functions correctly.
Runtime layer: application is running with structured logging, probes, and configuration separation in place.
Intelligence layer: at least one AI tooling use documented using the Week 10 eight-field format.
End-to-end integration test passed: request in, structured log out, correlation ID traceable.
All success criteria from the scope document are demonstrable in a five-minute demo.


----------------------------------------------------------------------------------------------


Documentation & Workflow Organization
A working system with poor documentation is a system only its author can operate. The capstone repository is your portfolio artefact: it will outlast this course and will be reviewed by engineers who have never spoken to you. This page covers the standards that make a repository legible to a stranger in under five minutes.


Why This Matters
Osei's standard from Week 9 applies to the capstone: "If someone clones your repository, runs the setup commands, and gets a working system, you have built something worth showing." Documentation is not separate from engineering: it is the part of engineering that makes everything else transferable. A senior engineer reviewing a candidate's portfolio spends the first two minutes on the README. If those two minutes do not tell them what the system does, what problem it solves, and how to run it, the rest of the repository does not get reviewed.


What Good Looks Like
Repository structure
The capstone repository must follow a consistent directory structure. Every directory must have a clear purpose. No files at the root that belong in a subdirectory. No directories named "misc", "temp", or "old".

# Track A: Infrastructure-first structure
kijani-capstone/
├── README.md
├── docs/
│   ├── architecture.png
│   └── runbook.md
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── ansible/
│   ├── playbook.yml
│   └── inventory/
├── k8s/
│   ├── kk-payments-deployment.yaml
│   ├── kk-payments-service.yaml
│   ├── kk-payments-configmap.yaml
│   └── kijani-ingress.yaml
├── Jenkinsfile
└── monitoring/
    ├── prometheus.yml
    └── alerts.yml

# Note: if you have not configured Prometheus before, start from
# prometheus.io/docs/prometheus/latest/configuration/alerting_rules
# A minimal alert firing when kk-payments error rate > 5% for 2 minutes
# is sufficient. Alternatively, implement the log-based error rate pattern
# from Week 7 as a vendor-agnostic alternative.

# Track B: Serverless-first structure
kijani-capstone/
├── README.md
├── docs/
│   ├── architecture.png
│   └── ai-governance-log.md
├── serverless.yml
├── handlers/
│   ├── receipts.js
│   ├── processor.js
│   ├── notifier.js
│   └── analytics.js
├── k8s/
│   └── (Week 9 kk-payments manifests + ConfigMap update
│       adding the S3 receipt bucket env var connecting
│       the Kubernetes layer to the serverless chain)
└── Jenkinsfile
README requirements
The README must answer these questions in order, without the reader having to search:

What is this? One paragraph. What system, what it does, what problem it solves.
Architecture: The diagram from the scope document, embedded or linked, with a one-sentence description of each major component.
Prerequisites: Every tool that must be installed before the setup commands will work. Include versions where relevant.
Setup: The exact commands to run, in order, to reproduce the system from scratch. No steps that require prior knowledge of the system.
How to run the pipeline: How to trigger the CI/CD pipeline and what to expect at each stage.
How to verify it works: The specific commands or requests that confirm the system is functioning correctly, matching the success criteria from the scope document.
Known limitations: What does not work, what is out of scope, and what would need to change for production use. This is the production readiness gap analysis in condensed form.
Naming conventions
Item	Convention	Example
Kubernetes manifests	{service}-{resource-type}.yaml	kk-payments-deployment.yaml
S3 buckets	kijani-{service}-{purpose}-{stage}	kijani-payments-receipts-staging
Serverless functions	camelCase verb + noun	generateReceipt, processUpload
Terraform resources	snake_case, descriptive	kijani_staging_bucket, kijani_receipts_role
Git branches	type/description	feature/staging-pipeline, fix/bucket-name-mismatch

How to Do It
Write the README before you think it is finished. Start the README on day one of the capstone build. Update it after every session. A README written at the end, from memory, misses the steps that feel obvious to you but are invisible to a newcomer. The test: give the README to a classmate who has not seen your capstone and ask them to follow the setup steps without asking you questions. Every question they ask is a gap in the README.

 

Use the architecture diagram twice. The diagram in the README is the same diagram from your scope document. If the system changed during the build, update the diagram. A README with a diagram that does not match the code is worse than a README with no diagram: it actively misleads the reader.

 

Document the AI governance log. Create docs/ai-governance-log.md. Every time you use an AI tool during the capstone build, add an entry using the eight-field format defined on Page 2. This is required for the intelligence layer assessment. One entry is sufficient if your AI use was limited. Three to five entries demonstrate a consistent governance practice.


Checklist Before Moving to Page 4
Repository follows the track-appropriate directory structure with no unnamed or temp directories.
README covers all seven required sections: what it is, architecture, prerequisites, setup, pipeline, verification, known limitations.
Architecture diagram present in docs/ and embedded or linked in the README.
All files follow the naming conventions table above.
docs/ai-governance-log.md exists with at least one entry in the Week 10 eight-field format.
Setup steps verified: a classmate or fresh shell can follow the README without asking questions.

-------------------------------------------------------------------------------------------------

Applying Version Control
The capstone build spans multiple sessions. Without deliberate version control practice, the repository history becomes a series of "fix" and "update" commits that tell a reviewer nothing about how the system evolved or what decisions were made along the way. This page covers the version control habits that turn a git log into an engineering record.


Why This Matters
In a professional DevOps team, the git history is the primary audit trail for infrastructure and application changes. When an incident occurs at 02:00, the on-call engineer reads the git log to find what changed in the last 24 hours. Commits like "fix stuff" or "update config" are not audit trails: they are noise. Commits like "fix: correct bucket name mismatch between serverless.yml and kk-payments env" tell the incident responder exactly what changed and why in under five seconds.

The capstone assessor reviews your commit history. Thirty commits with clear messages and a logical branching structure demonstrate professional practice. Ten commits with vague messages do not, regardless of how good the code is.


What Good Looks Like
Commit message format
Use conventional commits. The format is type: description where type is one of:

Type	Use for	Example
feat	A new component, function, or capability	feat: add kk-analytics serverless function with S3 trigger
fix	A bug or misconfiguration correction	fix: correct S3 prefix rule from notify- to notification-
infra	Terraform, Ansible, or serverless.yml changes	infra: add kijani-staging namespace to Terraform module
ci	Pipeline configuration changes	ci: add staging deploy stage before production approval gate
docs	README, architecture diagram, or runbook updates	docs: add architecture diagram to README and docs/ directory
Note: "docs: add architecture diagram to README" and "docs: add prerequisites section to README setup steps" are two separate commits, not one. Each logical change gets its own commit.
test	Test additions or pipeline test stage changes	test: add smoke test for kk-payments health endpoint
Branching strategy
Use feature branches for each logical unit of capstone work. Merge to main when a feature is complete and tested. Do not commit directly to main during development. If working in a pair, prefix branch names with your username (e.g. alice/feature/staging-pipeline) and use pull requests to merge into main so both contributors review each other's work.

# Recommended branch sequence for the capstone
main
├── feature/infrastructure-layer      (Terraform + Ansible, or serverless resources block)
├── feature/delivery-pipeline         (Jenkinsfile updates)
├── feature/runtime-configuration     (Kubernetes manifests, probes, limits)
├── feature/ai-governance             (governance log, checklist documentation)
└── feature/monitoring                (Prometheus rules and Grafana dashboards, if applicable)
Tagged release
Create at least one annotated git tag marking the state of the repository at capstone submission:

git tag -a v1.0.0 -m "Capstone submission: Track A, staging pipeline with approval gate and Prometheus alerting"
git push origin v1.0.0
The tag message should summarise what the release contains. The annotated tag (using -a) stores the message, the tagger, and the timestamp in git history. A lightweight tag (without -a) does not. Use annotated tags for submission artefacts.


How to Do It
Commit early, commit often, commit small. Each commit should represent one logical change. "Add Terraform staging namespace and update Jenkins deploy stage" is two commits. Keeping commits atomic makes the history readable and makes it possible to revert a single change without undoing unrelated work.

 

Never commit secrets. This was a Week 5 rule, a Week 9 rule, and a Week 10 rule. It is the capstone rule too. Run git grep -i password and git grep -i secret and git grep -i api_key before every push. If any match appears in a file other than a .example file, do not push. Fix it first.

 

Use pull requests even when working solo. A PR on your own repository forces you to review the diff before merging. During the capstone, this review catches the configuration errors and missing documentation that would otherwise reach main unnoticed. The PR description should state what changed and why, matching the commit message format.

 

What the assessor sees when reviewing your git history: whether you worked iteratively or in one large dump, whether commit messages are informative or vague, whether feature branches were used, and whether a release tag exists. A history that shows 25 small commits across five feature branches with clear messages demonstrates professional practice. A history that shows 3 large commits directly to main does not, even if the final code is identical.

Checklist Before Moving to Page 5
All commits use the conventional commit format: type: description.
No commits directly to main during development: all changes via feature branches.
At least one pull request in the repository history with a description explaining what changed and why.
git grep finds no secrets, passwords, or API keys in committed files.
At least 15 commits with meaningful messages spread across the capstone build period. Spread means commits appear across at least three separate calendar days: a repository with 15 commits all on the final day does not demonstrate iterative development. The assessor will check with git log --format="%ad %s" --date=short.
Annotated release tag v1.0.0 created and pushed to the remote repository.

----------------------------------------------------------------------------------

Testing and Feedback Integration
A system that has only been tested by the person who built it is a system with undiscovered bugs. The capstone requires a peer testing session not because external feedback is a formality, but because the most valuable thing another engineer brings to your work is the ability to see gaps that familiarity has made invisible to you.


Why This Matters
In Week 10, Nia required a production readiness gap analysis because she knew Amina was too close to her own work to see it objectively. The peer testing session in the capstone serves the same function. The reviewer is not a quality assurance engineer running formal test cases: they are an engineer with the same technical background who follows your README, attempts to trigger your pipeline, and tells you what was unclear, what failed, and what surprised them.

The skill being assessed here is not whether your system has zero bugs. It is whether you can receive technical feedback, evaluate it, and make a specific improvement. That is the feedback loop that characterises senior engineering practice.


What Good Looks Like
The test plan
Before the peer session, write a one-page test plan. It is not a formal test specification: it is a list of the specific things you want your reviewer to try, in order, so they can exercise the system systematically rather than at random.

A strong capstone test plan covers:

Fresh setup: Can the reviewer clone the repository and follow the README to get the system running without help?
Happy path: The primary user journey from end to end. For KijaniKiosk: push a commit, watch the pipeline, approve the production gate, confirm the application is running and requests are handled.
Failure path: Introduce a deliberate fault (bad image tag, missing ConfigMap value, incorrect bucket name) and verify the system responds as designed (stalls gracefully, rolls back, logs a clear error).
AI governance: Ask the reviewer to read your ai-governance-log.md and assess whether the documented human review steps are credible and specific.
 

The peer feedback log
During and after the testing session, log every issue raised. Each entry must have:

Issue: What the reviewer found (specific, not "it was confusing").
Severity: Blocks setup / breaks functionality / unclear documentation / minor improvement.
Resolution: What you changed in response, or a specific reason for not changing it.
Evidence: A commit hash or screenshot showing the change was made.
The minimum improvement standard
At least one issue from the peer feedback log must result in a documented change to the repository. The change does not need to be large: it can be a clarification in the README, a corrected prerequisite version, or a fixed configuration value. What matters is the evidence that the feedback loop completed: issue raised, issue evaluated, improvement made, change committed.


How to Do It
Run the peer session in the second-to-last capstone session, not the last. The recommended timeline in the Capstone Project Submission Guide schedules the peer session for Session 4: two sessions before the deadline, leaving one full session to implement improvements before submission.

If the session is the day before submission, there is no time to implement improvements. Run it early enough that you have at least one session to address the feedback before the final submission.

 

Brief the reviewer before they start. Tell them what the system is and what track you chose. Do not walk them through the setup: the README is supposed to do that. Your brief is one paragraph. Then hand over the keyboard (or screen share) and watch silently. Note everything they try, not just what fails.

 

Use GitHub Issues to log the feedback (required for the Exemplary grade level on Dimension 6). Create an issue for each item raised during the session. Tag them with labels: bug, documentation, enhancement. Closing an issue with a commit reference (using "Closes #3" in the commit message) creates an automatic link between the issue and the fix in the repository history. This is the evidence chain the assessor follows.

 

# Example: commit that closes a peer review issue
git commit -m "docs: add Java 11+ prerequisite for serverless-s3-local fallback

Closes #3 - peer reviewer could not start the S3 local server because
Java was not listed as a prerequisite in the README. Added to the
prerequisites section with version requirement and install link."
If you cannot find a peer reviewer: conduct a self-review session using a different machine or a fresh terminal session with no environment variables pre-set. Document it as a self-review in the feedback log and note any issues found. A documented self-review with a resolved improvement is preferable to no feedback log. Grade expectation: a well-documented self-review scores at the Developing level (6-9 points) on Dimension 6: not because the quality is lower, but because the external perspective a peer provides cannot be fully replicated. A peer review is strongly recommended if Exemplary is your target.

KijaniKiosk Example: A Useful Peer Feedback Entry
Amina runs a peer session with a classmate. Her classmate documents this issue:

"Issue: README says 'run serverless offline start' but does not say to run it from the kk-receipts directory. I ran it from the repository root and got 'no serverless.yml found'. Severity: blocks setup. Suggested fix: add a cd command before the serverless command in the README setup section."
Amina's resolution: adds cd kijani-serverless/kk-receipts && serverless offline start to the README. Commits with message docs: clarify serverless offline working directory in setup steps - Closes #7. The issue is closed with a link to the commit. The feedback loop is complete and documented.


Checklist Before Moving to Page 6
Test plan written and shared with the reviewer before the session.
Peer review session completed with at least one classmate (or documented self-review).
Peer feedback log contains at least three entries with issue, severity, resolution, and evidence.
At least one improvement implemented and committed with a GitHub Issue reference.
GitHub Issues (or equivalent log) accessible in the repository, with at least one closed issue linked to a commit.


-----------------------------------------------------------------------------------------------

Presenting & Reflecting on the Project
You have built a system, documented it, tested it, and improved it based on feedback. The final requirement is to demonstrate it to an audience and articulate what you learned. The presentation is not a summary of the features: it is an argument for the architectural decisions you made, including the ones that turned out to be wrong.


Why This Matters
A DevOps engineer who can build systems but cannot explain them is limited in their impact. The decisions that shape a production system, the trade-offs between reliability and cost, between automation speed and human oversight, between tight coupling and operational simplicity, are made and communicated in meetings, in Slack, and in technical reviews. The presentation is your practice for those conversations.

CAP-6 is assessed on two things: the clarity of the technical story and the honesty of the reflection. A presentation that claims everything worked perfectly and the system is production-ready scores lower than one that names specific gaps, explains the trade-offs that caused them, and states what would need to change to address them.


What Good Looks Like
The live demo (5-8 minutes)
The demo must show the system working, not the code. The audience does not want to watch you scroll through handler files: they want to see a curl trigger a pipeline that deploys an application and produces structured logs. Plan the demo sequence before you start:

Start with the end state: Show the running system first. One curl, one response, three log lines. This establishes that it works before you explain how.
Show the pipeline: Trigger a deploy and walk through the stages in real time, including the approval gate pause.
Show a failure and recovery: Introduce a deliberate fault and show the system responding. Rolling back, stalling safely, or logging a clear error. This demonstrates that you designed for failure, not just for success.
Show the governance: Open the ai-governance-log.md. Read one entry. Show that you used AI tooling, checked it, found a gap, and fixed it. This takes 60 seconds and demonstrates the Week 10 skills directly.
The slide deck (6-10 slides, PDF)
Slide	Content
1. Title	Project name, track, your name, date
2. Problem	The specific operational gap from your scope document. One paragraph, no more.
3. Architecture	The architecture diagram. Label every component and every connection. Be prepared to explain any arrow on the diagram.
4. Key Decision	One technical decision you made that was not obvious. What you chose, what you did not choose, and why. This is the slide that differentiates strong presentations from adequate ones.

Strong example: "I chose bucket chaining over SQS because it required no cloud account for local testing, consistent with the vendor-agnostic policy. The trade-off is no retry guarantee on processor crash. In production I would add a DLQ."
Weak example: "I chose serverless because it is scalable." The strong version names what was not chosen, why the trade-off was acceptable, and what would change in production.
5. AI Tooling	How you used AI assistance. What it got right. What it got wrong. What you changed before applying the output. One sentence per point.

If you cannot identify what the AI got wrong: run the AI-generated code or configuration through the Week 10 six-point governance checklist. At least one checklist control will identify a gap in any AI-generated infrastructure code. Name that specific gap on this slide.
6. Production Gaps	Two or three specific things that would need to change before this system could handle real KijaniKiosk customer traffic. Named components, named gaps, named fixes. Not "more security".
7-10. Optional	Additional technical depth, monitoring screenshots, governance log excerpts, or peer feedback evidence. Only include if they add to the story.
The reflection document (1 page)
The reflection is not a summary of what you built. It answers three specific questions:

What did you get wrong? Name the specific technical decision that turned out differently from how you planned it, and explain what you would do differently with the knowledge you now have.
What is the most important thing you learned? Not a list. One thing. The concept, the week it appeared in the course, and what specifically changed in how you think about software delivery.
What would a second pass look like? If you had two more weeks and everything you built as a starting point, what would you add, remove, or change? This question has no wrong answer if it is specific.

How to Do It
Rehearse the demo at least twice. The first rehearsal finds the steps you do from muscle memory that are not documented anywhere. The second rehearsal confirms the timing and finds any race conditions in your demo sequence (the pipeline takes longer than expected, the Kubernetes rollout stalls, the local S3 server needs an extra startup second). Demo failures in presentations are almost never technical failures: they are rehearsal failures.

Prepare a demo fallback. If the live demo fails, you need to be able to continue the presentation. Take screenshots of every key moment in the system working correctly: the pipeline approval stage, the three log lines from the serverless chain, the kubectl rollout status confirmation. If the live demo fails, the screenshots prove it worked.

Write the reflection last. The reflection is written after the demo, not before. You cannot write honestly about what you got wrong until you have seen it in front of an audience. Reserve thirty minutes after the demo to write the reflection while the gaps are still visible. If you present in the final session of the day, you have until the following morning to submit the reflection: use that time. A reflection written after sleeping on the demo often identifies gaps that adrenaline masks during the presentation itself.


Checklist Before Submitting the Capstone
Demo rehearsed at least twice. Demo fallback screenshots prepared and accessible.
Slide deck is 6-10 slides covering all six required sections. Exported as PDF.
Reflection document is one page, answers all three questions with specific answers. Not a feature list.
Architecture slide diagram matches the actual system (not the original scope diagram if the system changed).
AI tooling slide names what was correct, what was wrong, and what was changed. "The AI was entirely correct" fails this requirement.
Production gaps slide names specific components, specific gaps, and specific remediations.


--------------------------------------------------------------------------------------------

Capstone Project Submission Guide
Capstone Project: KijaniKiosk End-to-End Delivery
Ten weeks ago, KijaniKiosk had no pipeline, no Infrastructure as Code, no containers, and no observability. You have built all of it, week by week, using the same codebase, the same personas, and the same production standards.

The capstone is the final question: can you take what you have built and extend it into something that meets a production engineering bar? Not a polished demo built overnight, but a system that reflects deliberate design choices, honest assessment of its own gaps, and the kind of documentation that makes it transferable to another engineer.

Nia's final requirement: "When this is done, I want to be able to hand the repository to a new engineer on the team and have them contribute meaningfully within a day. That is the standard."


Choose Your Track
Both tracks build on the same KijaniKiosk codebase. Both are assessed on the same rubric. Choose the track that lets you demonstrate the most depth in the areas you care about most.

Track A: Infrastructure-First
You extend the KijaniKiosk deployment into a multi-environment, monitored, production-approaching system. This track is for learners who want to go deep on IaC, pipeline automation, and observability.

Required components:

A kijani-staging namespace provisioned by Terraform and configured by Ansible, isolated from the default production namespace.
A Jenkins pipeline that deploys to staging automatically on merge to main, runs a smoke test against the staging deployment, and only offers the production approval gate after the smoke test passes.
kk-payments running in staging with environment-specific ConfigMaps (different DB_HOST from production) and the same Deployment manifest used for both environments.
At least one monitoring signal for kk-payments committed to the repository. Option A: a Prometheus alert rule (prometheus.io/docs/prometheus/latest/configuration/alerting_rules) that fires when error rate exceeds 5% for 2 minutes. Option B: a log-based error rate calculation following the Week 7 SLO pattern, reading from kk-payments structured logs and outputting a summary to a monitoring file. Both options demonstrate the same observability principle. Option A requires Prometheus installed; Option B requires only the existing structured logging.
The Week 10 serverless receipt chain integrated: kk-payments in the staging environment writes to the kk-payments-receipts-staging bucket and the receipt chain fires correctly.
Track B: Serverless-First
You extend the Week 10 serverless receipt chain into a complete production-approaching system with a fourth function, a real cloud deployment, and documented governance. This track is for learners who want to go deep on serverless architecture, event-driven design, and AI governance.

Required components:

A fourth function, kk-analytics, triggered by kk-notifier's output bucket, that aggregates receipt events (count, total amount, timestamp range) and logs a structured summary.
The full four-function stack deployed using serverless deploy --stage staging. Preferred: deploy to a real cloud provider (AWS free tier, Google Cloud Functions free tier, or Cloudflare Workers free tier) with serverless info output as confirmation. Acceptable alternative: deploy using serverless-offline in production-mode configuration and use serverless print --format yaml as verification output. Cloud deployment demonstrates the full production path; the local alternative is assessed at Proficient rather than Exemplary for this component.
The Thursday governance checklist applied to the deployed stack: all six controls assessed against the actual deployed configuration, not against a local mock, with documented findings and remediations.
The kk-payments Kubernetes deployment (from Week 9) writing receipt events to the production S3 bucket that triggers the chain. The connection between the Kubernetes layer and the serverless layer is the integration seam to demonstrate.
A Jenkins pipeline update that deploys the serverless stack to staging as part of the pipeline, with the approval gate before the production serverless deploy stage.

What to Submit
All six deliverables are required for both tracks. Partial submissions are assessed on the rubric at their actual completion state.

#	Deliverable	Format	
1	Project scope document: problem statement, track, in-scope components, out-of-scope items, success criteria, architecture diagram	1 page PDF + PNG diagram	
2	Working repository: structured according to CAP-3 conventions, README complete, all track components implemented and functional	GitHub repository link	
3	Pipeline demonstration: CI/CD pipeline running end-to-end with approval gate visible, at least one deploy to staging and one to production shown	Loom video (max 5 minutes narrated; up to 8 minutes total including automated pipeline stages) or screenshot sequence	
4	Peer feedback log: at least three issues documented with severity and resolution, at least one resolved improvement committed with a GitHub Issue reference	GitHub Issues link or PDF log	
5	Slide deck: 6-10 slides covering the six required sections from Page 6	PDF	
6	Reflection document: one page answering the three required questions from Page 6 with specific, honest responses	PDF or Markdown in repository	

Timeline and Support
Session	Recommended focus
Capstone Session 1	Scope document and architecture diagram complete. Track chosen. Repository created with initial directory structure.
Capstone Session 2	Infrastructure layer complete and reproducible. Delivery layer started.
Capstone Session 3	Delivery and runtime layers complete. Intelligence layer started. README first draft.
Capstone Session 4	Peer review session. Feedback log started. At least one improvement committed.
Capstone Session 5	Slide deck complete. Demo rehearsed twice. Release tag created. All deliverables assembled.
Presentation Day	Live demo and slide presentation. Reflection written after demo. Final submission uploaded.
Where to find the grading criteria
The full 8-dimension rubric and grade boundaries appear on the Capstone Project Submission assignment page. Review it before starting your capstone work: the rubric specifies what is required at each level (Developing / Approaching / Proficient / Exemplary) and what the non-negotiable requirements are for academic integrity.

Submission deadline: End of Presentation Day session. The reflection document may be submitted up to 24 hours after the live presentation.


------------------------------------------------------------------------------------------

Capstone Project Submission
Due No due date Points 100 Submitting a website url
Capstone Project: KijaniKiosk End-to-End Delivery
Ten weeks ago, KijaniKiosk had no pipeline, no Infrastructure as Code, no containers, and no observability. You have built all of it, week by week, using the same codebase, the same personas, and the same production standards.

The capstone is the final question: can you take what you have built and extend it into something that meets a production engineering bar? Not a polished demo built overnight, but a system that reflects deliberate design choices, honest assessment of its own gaps, and the kind of documentation that makes it transferable to another engineer.

Nia's final requirement: "When this is done, I want to be able to hand the repository to a new engineer on the team and have them contribute meaningfully within a day. That is the standard."


Choose Your Track
Both tracks build on the same KijaniKiosk codebase. Both are assessed on the same rubric. Choose the track that lets you demonstrate the most depth in the areas you care about most.

Track A: Infrastructure-First
You extend the KijaniKiosk deployment into a multi-environment, monitored, production-approaching system. This track is for learners who want to go deep on IaC, pipeline automation, and observability.

Required components:

A kijani-staging namespace provisioned by Terraform and configured by Ansible, isolated from the default production namespace.
A Jenkins pipeline that deploys to staging automatically on merge to main, runs a smoke test against the staging deployment, and only offers the production approval gate after the smoke test passes.
kk-payments running in staging with environment-specific ConfigMaps (different DB_HOST from production) and the same Deployment manifest used for both environments.
At least one Prometheus alert rule that fires on a meaningful kk-payments health signal (error rate, latency, or pod restart count). Alert configuration committed to the repository.
The Week 10 serverless receipt chain integrated: kk-payments in the staging environment writes to the kk-payments-receipts-staging bucket and the receipt chain fires correctly.
Track B: Serverless-First
You extend the Week 10 serverless receipt chain into a complete production-approaching system with a fourth function, a real cloud deployment, and documented governance. This track is for learners who want to go deep on serverless architecture, event-driven design, and AI governance.

Required components:

A fourth function, kk-analytics, triggered by kk-notifier's output bucket, that aggregates receipt events (count, total amount, timestamp range) and logs a structured summary.
The full four-function stack deployed to a real cloud provider using serverless deploy --stage staging. Local development confirmed with serverless-offline; production deployment confirmed with serverless info output.
The Thursday governance checklist applied to the deployed stack: all six controls assessed against the actual deployed configuration, not against a local mock, with documented findings and remediations.
The kk-payments Kubernetes deployment (from Week 9) writing receipt events to the production S3 bucket that triggers the chain. The connection between the Kubernetes layer and the serverless layer is the integration seam to demonstrate.
A Jenkins pipeline update that deploys the serverless stack to staging as part of the pipeline, with the approval gate before the production serverless deploy stage.

What to Submit
All six deliverables are required for both tracks. Partial submissions are assessed on the rubric at their actual completion state.

#	Deliverable	Format	Skills map
1	Project scope document: problem statement, track, in-scope components, out-of-scope items, success criteria, architecture diagram	1 page PDF + PNG diagram	CAP-1
2	Working repository: structured according to CAP-3 conventions, README complete, all track components implemented and functional	GitHub repository link	CAP-2, CAP-3
3	Pipeline demonstration: CI/CD pipeline running end-to-end with approval gate visible, at least one deploy to staging and one to production shown	Loom video (max 5 minutes) or screenshot sequence	CAP-2
4	Peer feedback log: at least three issues documented with severity and resolution, at least one resolved improvement committed with a GitHub Issue reference	GitHub Issues link or PDF log	CAP-5
5	Slide deck: 6-10 slides covering the six required sections from Page 6	PDF	CAP-6
6	Reflection document: one page answering the three required questions from Page 6 with specific, honest responses	PDF or Markdown in repository	CAP-6

Timeline and Support
Session	Recommended focus
Capstone Session 1	Scope document and architecture diagram complete. Track chosen. Repository created with initial directory structure.
Capstone Session 2	Infrastructure layer complete and reproducible. Delivery layer started.
Capstone Session 3	Delivery and runtime layers complete. Intelligence layer started. README first draft.
Capstone Session 4	Peer review session. Feedback log started. At least one improvement committed.
Capstone Session 5	Slide deck complete. Demo rehearsed twice. Release tag created. All deliverables assembled.
Presentation Day	Live demo and slide presentation. Reflection written after demo. Final submission uploaded.
Submission deadline: End of Presentation Day session. The reflection document may be submitted up to 24 hours after the live presentation.

Score Summary
Dimension	CAP	Max Points	Score
1. Project Scope and Planning	CAP-1	10	 
2. Pipeline Completeness and Automation	CAP-2	20	 
3. AI Tooling Integration and Governance	CAP-2 + Week 10	10	 
4. Repository Structure and Documentation	CAP-3	15	 
5. Version Control Hygiene	CAP-4	10	 
6. Testing and Feedback Integration	CAP-5	15	 
7. Presentation and Live Demo	CAP-6	10	 
8. Reflection Quality	CAP-6	10	 
Total	100	 
Grade boundaries: 90-100 = Distinction | 75-89 = Merit | 60-74 = Pass | Below 60 = Resubmission required

Resubmission: One resubmission permitted within 5 working days of results. Maximum grade on resubmission: 75 (Merit ceiling). Resubmission must address all dimensions scoring below 5.

Academic integrity: All submitted code must be the learner's own work. AI-generated code is permitted subject to the documentation requirements in Dimension 3. Undisclosed AI-generated code (code not documented in the governance log) constitutes an academic integrity violation.

Rubric
Capstone Project Rubric
Capstone Project Rubric
Criteria	Ratings	Pts
This criterion is linked to a learning outcomeDimension 1: Project Scope and Planning (CAP-1)
10 Pts
Exemplary
Scope document is one page. Problem statement names a specific, verifiable operational gap. In-scope items are five or fewer, each in one sentence. Out-of-scope items list at least two exclusions with reasons. Success criteria are measurable and each is directly demonstrable in the live demo. Architecture diagram shows all components and labels every connection with what flows across it.
8 Pts
Proficient
Scope document addresses all five questions. Problem statement is specific but one success criterion is vague or not directly demonstrable. Architecture diagram is present and mostly complete with minor unlabelled connections.
6 Pts
Developing
Scope document is present but problem statement is generic ("improve the system") or success criteria cannot be verified in a demo. Architecture diagram is incomplete or does not match the actual system built.
4 Pts
Beginning
Scope document is missing, is less than half a page, or does not address the problem statement and success criteria. No architecture diagram submitted.
10 pts
This criterion is linked to a learning outcomeDimension 2: Pipeline Completeness and Automation (CAP-2)
20 Pts
Exemplary
All four layers (infrastructure, delivery, runtime, intelligence) are present and working. Infrastructure is reproducible from a clean checkout. A merge to main triggers the pipeline without manual steps. The approval gate functions correctly and records an approval reason. The application is running with structured logs, probes, resource limits, and configuration separation. A deliberate fault is introduced and handled gracefully in the demo. (Track A: staging pipeline with smoke test demonstrated. Track B: serverless stack deployed to real cloud provider demonstrated.)
17 Pts
Proficient
Three of four layers are complete and working. The pipeline runs but one stage requires a manual step not in the README, or the approval gate is present but does not capture an approval reason. The fault handling demo is missing but the happy path works correctly.
13 Pts
Developing
Two layers are complete. Pipeline runs but significant manual steps are required that are not documented. Application is deployed but missing probes, resource limits, or configuration separation. The track-specific requirement (staging environment or cloud deployment) is absent or non-functional.
8 Pts
Beginning
Fewer than two layers working. Pipeline does not run or requires extensive undocumented manual intervention. Application cannot be demonstrated as running in the target environment.
20 pts
This criterion is linked to a learning outcomeDimension 3: AI Tooling Integration and Governance (CAP-2 + Week 10)
10 Pts
Exemplary
docs/ai-governance-log.md contains at least two entries in the Week 10 eight-field format (defined on Page 2 of the capstone guide). Each entry names what the AI produced, what it got wrong, and what specific change the reviewer made. The "what it got wrong" field is never empty or "nothing". At least one governance checklist item (from the six-point list) is explicitly referenced in the log. The slide deck AI tooling slide matches the log entries.
8 Pts
Proficient
Governance log contains at least one entry with most eight fields completed. The "what it got wrong" field has a response but it is vague ("could be improved"). The slide deck references AI tooling use.
6 Pts
Developing
Governance log exists but has fewer than the required fields, or "what it got wrong" is empty or states "the AI was entirely correct" with no manual verification described. AI tooling was used but not documented in the governance format.
4 Pts
Beginning
No governance log submitted. No evidence of AI tooling use. Or governance log submitted but describes tool use without any critical assessment of the AI output.
10 pts
This criterion is linked to a learning outcomeDimension 4: Repository Structure and Documentation (CAP-3)
15 Pts
Exemplary
Repository follows the track-appropriate directory structure. No unnamed or temp directories. All files follow naming conventions. README covers all seven required sections. Architecture diagram is present in docs/ and matches the actual system. A classmate can follow the README to a working system without asking questions. No secrets committed to any file. docs/ai-governance-log.md present.
12 Pts
Proficient
Directory structure is mostly correct with one or two files in the wrong location. README covers five or six of the seven sections. Architecture diagram present but does not match the current system state. One minor undocumented prerequisite in the setup steps.
9 Pts
Developing
README exists but is missing three or more required sections. Directory structure does not follow conventions: files at root level that belong in subdirectories, or temp directories present. Architecture diagram is missing or is the original scope diagram unchanged from a system that diverged during the build.
5 Pts
Beginning
No README, or README is a single paragraph with no structure. Repository is a flat list of files with no directory organisation. Secrets committed to the repository.
15 pts
This criterion is linked to a learning outcomeDimension 5: Version Control Hygiene (CAP-4)
10 Pts
Exemplary
All commits use the conventional commit format. No direct commits to main during development. At least two feature branches visible in the git history. At least one pull request with a meaningful description. At least 15 commits with informative messages spread across at least three separate calendar days (verifiable with git log --format="%ad %s" --date=short). Annotated release tag v1.0.0 created and pushed. No commit messages that are "fix", "update", "wip", or similar.
8 Pts
Proficient
Most commits use conventional format with two or three vague messages. One or two direct commits to main. At least one feature branch present. Release tag exists but is lightweight rather than annotated. Between 10 and 14 total commits.
6 Pts
Developing
Fewer than 10 commits, or most commits have vague messages ("fix", "update"). All commits directly to main. No feature branches. Release tag absent or created after the submission deadline.
4 Pts
Beginning
Fewer than five commits. No conventional commit format. No branching. Repository appears to have been committed in one or two large batches at the end of the project.
10 pts
This criterion is linked to a learning outcomeDimension 6: Testing and Feedback Integration (CAP-5)
15 Pts
Exemplary
Peer review session completed with a classmate. Feedback log contains at least three entries with issue, severity, resolution, and evidence (commit hash or screenshot). At least one GitHub Issue is closed with a commit reference (required for Exemplary; Developing level is awarded for a documented self-review). The improvement is visible in the repository: a before/after comparison is possible using the commit history. Test plan was written before the session and is included in the submission.
12 Pts
Proficient
Peer review session completed. Feedback log has at least three entries but resolution evidence is missing for one or two items. One improvement committed but the GitHub Issue is not linked to the commit. Test plan absent but the session itself is documented.
9 Pts
Developing
Self-review documented in place of a peer session. Feedback log has fewer than three entries. No improvement committed to the repository, or the improvement is committed but not connected to any feedback item. No test plan.
5 Pts
Beginning
No feedback log submitted. No evidence of any testing session, peer or self-directed. No improvements attributable to testing feedback.
15 pts
This criterion is linked to a learning outcomeDimension 7: Presentation and Live Demo (CAP-6)
10 Pts
Exemplary
Live demo shows the system working end-to-end including the approval gate and a fault handling scenario. Slide deck covers all six required sections. The Key Decision slide names a genuine technical trade-off (not a feature description). AI tooling slide entries match the governance log. Production gaps slide names specific components and specific remediations. Presenter can answer technical questions about any arrow in the architecture diagram.
8 Pts
Proficient
Live demo shows the happy path working. Fault handling not demonstrated but screenshot fallback is available. Slide deck present with five of six required sections. Key Decision slide describes a decision but does not clearly articulate the trade-off. Production gaps slide identifies gaps without naming specific remediations.
6 Pts
Developing
Live demo fails and no screenshot fallback is available, or demo runs but the approval gate is not shown. Slide deck has fewer than five required sections. No Key Decision slide. Production gaps slide says "more security" or similar without specifics.
4 Pts
Beginning
No live demo and no screenshot fallback. Slide deck not submitted or has fewer than four slides. Presenter cannot answer basic technical questions about their own architecture.
10 pts
This criterion is linked to a learning outcomeDimension 8: Reflection Quality (CAP-6)
10 Pts
Exemplary
Reflection document is one page. All three required questions are answered with specific, honest responses. "What did you get wrong" names a specific technical decision and explains why a different approach would have been better. "Most important thing learned" names one concept, the week it appeared, and what changed in thinking. "Second pass" names specific additions, removals, or changes, not general improvements. Reflection could not be written by someone who did not complete this specific project.
8 Pts
Proficient
All three questions answered. "What did you get wrong" names a specific decision. "Most important thing learned" identifies a concept but the explanation of what changed in thinking is vague. "Second pass" mentions specific areas but descriptions are general rather than component-specific.
6 Pts
Developing
Two of three required questions answered. "What did you get wrong" says everything went as planned, or identifies a problem without explaining what should have been done differently. Reflection reads like a project summary rather than a personal technical analysis.
4 Pts
Beginning
Reflection not submitted, or reflection is a list of features built with no personal analysis. Generic answers that could apply to any DevOps course without modification.
10 pts
Total points: 100


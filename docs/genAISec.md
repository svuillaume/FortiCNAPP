# Securing the GenAI Stack: A Layered Look at the Attack Surface — Fortinet, and the Broader Vendor Landscape

*From the developer's laptop to the LLM endpoint in your cloud, GenAI has quietly redrawn the enterprise attack surface. Here is a clean, practical view of what's changed, real attacks already happening at each layer, where the Fortinet Security Fabric fits in — and the best-of-breed vendors covering each layer alongside it.*

---

## Why this matters now

Generative AI is no longer a side project. Developers are "vibe coding" with Copilot and Cursor, applications are calling LLM APIs at runtime, knowledge bases are being indexed into vector stores for RAG, and the Model Context Protocol (MCP) is connecting models to live tools and data sources.

Each of these shifts introduces a new layer of risk. And like any new architecture, GenAI does not replace the security fundamentals — it **stacks new concerns on top of them**.

This post walks through the five layers of a typical GenAI deployment, the main risks at each layer, recent real-world incidents, how the Fortinet portfolio maps to each layer, and the leading third-party vendors customers also evaluate. No agentic AI here — we are keeping the scope to LLM consumption, RAG, and MCP integrations.

---

## The five layers at a glance

1. **Developer Endpoint** — where code is written with AI assistance
2. **LLM API Consumption** — where your application talks to the model
3. **RAG Pipeline** — where retrieved data feeds the model
4. **MCP Integration** — where the model reads from connected tools
5. **Cloud & Model Infrastructure** — where it all runs

Let us take each in turn.

---

## Layer 1 — The Developer Endpoint

This is where "vibe coding" lives. Developers prompt AI assistants to generate, refactor, or autocomplete code at speeds that outpace traditional code review.

### The main risks

- **Insecure code at scale.** A December 2025 study of open-source pull requests found AI-generated code introduces **2.74x more security vulnerabilities** than human-written code. Veracode's 2025 GenAI Code Security Report tested 100+ LLMs and found AI introduced security vulnerabilities in **45% of cases**.
- **Sensitive data leaving the boundary.** Developers paste `.env` files, customer PII, or proprietary source into public LLM interfaces. Once submitted, it is gone.
- **Slopsquatting.** Commercial models hallucinate ~5% of suggested package names; open-source models up to ~22%. Attackers register the hallucinated names and lie in wait.

### Recent attacks

- **"Rules File Backdoor" — Pillar Security (March 2025).** Attackers embed invisible Unicode instructions inside `.cursorrules` or Copilot configuration files. When developers pull a poisoned repo, the AI assistant silently generates backdoored code. ([Pillar Security disclosure](https://www.pillar.security/blog/new-vulnerability-in-github-copilot-and-cursor-how-hackers-can-weaponize-code-agents))
- **"IDEsaster" — 24+ CVEs across AI IDEs (December 2025).** Researcher Ari Marzouk disclosed flaws across Cursor (**CVE-2025-49150, CVE-2025-54130, CVE-2025-61590**), GitHub Copilot (**CVE-2025-53773, CVSS 7.8**), Windsurf, Zed.dev, Roo Code, and JetBrains Junie. ([byteiota analysis](https://byteiota.com/ai-ide-security-crisis-30-flaws-expose-cursor-copilot/))
- **Cursor IDE RCE via MCP — CVE-2025-54135 / CVE-2025-54136 (August 2025).** Indirect prompt injection wrote a malicious `.cursor/mcp.json` configuration into the workspace, achieving persistent RCE across IDE restarts. ([WorkOS write-up](https://workos.com/blog/prompt-injection-attacks))

### Where Fortinet fits

- **[FortiSASE](https://www.fortinet.com/products/sase)** discovers shadow AI usage and applies DLP on outbound LLM traffic, on-network or remote, with integrated SWG, ZTNA, and CASB on a single agent.
- **[FortiClient](https://www.fortinet.com/products/endpoint-security/forticlient) / [FortiEDR](https://www.fortinet.com/products/endpoint-security/fortiedr)** enforces endpoint posture and blocks exfiltration from developer machines.
- **[FortiCNAPP — DSPM](https://www.fortinet.com/products/forticnapp)** matters here for a reason developers underestimate: vibe-coded apps frequently hardcode paths to S3 buckets, databases, or storage accounts the developer never classified. DSPM continuously discovers sensitive data flowing through AI-generated code paths and flags shadow data stores created by AI-suggested infrastructure.
- **[FortiCNAPP](https://www.fortinet.com/products/forticnapp) IaC + code scanning** catches insecure generated code, hardcoded secrets, and slopsquatting-style dependency risks in CI/CD before merge.
- **ZTNA via [FortiGate VM](https://www.fortinet.com/products/private-cloud-security/fortigate-virtual-appliances) + FortiClient + [FortiAuthenticator](https://www.fortinet.com/products/identity-access-management/fortiauthenticator)** matters because the developer endpoint is increasingly a privileged gateway into source repos, cloud consoles, and production data. ZTNA enforces per-application, identity-aware access — a compromised AI extension or malicious MCP server cannot freely lateral-move into production GitHub, Kubernetes, or cloud accounts.

### Other best-of-breed vendors at this layer

- **AI coding assistants with native enterprise security:** [GitHub Copilot Enterprise](https://github.com/features/copilot) (with IP indemnity and GHAS integration), [Amazon Q Developer](https://aws.amazon.com/q/developer/) (zero-data-retention by default), and [Tabnine Enterprise](https://www.tabnine.com/) (air-gapped deployment).
- **AI-aware SAST and code scanning:** [Snyk DeepCode AI](https://snyk.io/platform/deepcode-ai/), [Checkmarx](https://checkmarx.com/), [Veracode](https://www.veracode.com/), [SonarQube](https://www.sonarsource.com/) — proven SAST players who have integrated GenAI scanning paths.
- **GitHub Advanced Security (GHAS):** [Code Security and Secret Protection](https://github.com/security/advanced-security) — strong native option for GitHub-centric organizations.
- **MCP and AI dev-tool gateways:** [MintMCP](https://www.mintmcp.com/), [Backslash Security](https://www.backslash.security/), [TrueFoundry](https://www.truefoundry.com/) — emerging category for governing AI coding tools and MCP server access at the developer endpoint.

---

## Layer 2 — LLM API Consumption

When your application calls OpenAI, Anthropic, Bedrock, Vertex AI, or Azure OpenAI, you inherit a new flow of sensitive data leaving your perimeter — and a new untrusted input source coming back.

### The main risks

- **Prompt injection (direct and indirect).** OWASP ranks this as **LLM01:2025 — the #1 LLM risk**. ([OWASP LLM01:2025](https://genai.owasp.org/llmrisk/llm01-prompt-injection/))
- **Insecure output handling.** When model output is rendered as HTML, executed as code, or used in SQL, the LLM becomes a fresh vector for XSS, SSRF, and RCE.
- **Cost and availability impact.** Unbounded token consumption and adversarial long-context prompts drive runaway cloud spend. A leaked API key is now a financial DoS.

### Recent attacks

- **EchoLeak — CVE-2025-32711, Microsoft 365 Copilot (June 2025).** Disclosed by Aim Labs, the **first known zero-click prompt injection in a production LLM system**. An email triggered Copilot to retrieve internal documents and exfiltrate them to an attacker-controlled server with no user interaction. ([Academic paper](https://arxiv.org/pdf/2509.10540))
- **ChatGPT Connector data leakage (July–August 2025).** NSFOCUS documented incidents where indirect prompt injection through ChatGPT's connectors (Google Drive, SharePoint, GitHub) exfiltrated API keys, credentials, and confidential files. ([NSFOCUS analysis](https://nsfocusglobal.com/prompt-word-injection-an-analysis-of-recent-llm-security-incidents/))
- **ChatGPT Windows product key leak (July 2025).** A crafted "guessing game" prompt bypassed content filters and tricked ChatGPT into revealing valid Windows product keys, including an enterprise license tied to a major bank.

### Where Fortinet fits

- **[FortiAIGate](https://www.fortinet.com/products/fortiaigate)** is purpose-built for this layer. Deployed as a containerized LLM gateway between the application and the model (OpenAI, Anthropic, Bedrock, or self-hosted), it inspects every prompt and completion in real time, enforces guardrails against prompt injection and jailbreaking, prevents data exfiltration and model theft, blocks excessive token consumption, and provides per-interaction logging and cost tracking. It is the AI-aware control plane that traditional WAFs and API gateways were never designed to be. ([Fortinet AI Security overview](https://www.fortinet.com/solutions/ai-security))
- **[FortiWeb](https://www.fortinet.com/products/web-application-firewall/fortiweb) / [FortiAppSec Cloud](https://www.fortinet.com/products/web-application-firewall/fortiappsec-cloud)** protects the HTTP layer in front of your LLM-powered APIs — schema enforcement, rate limiting, bot mitigation, and OWASP coverage on the application surface.
- **[FortiGate VM](https://www.fortinet.com/products/private-cloud-security/fortigate-virtual-appliances)** inspects outbound traffic to external LLM providers with application-control awareness for AI SaaS and DLP on payloads.
- **[FortiCNAPP](https://www.fortinet.com/products/forticnapp) runtime behavior detection** delivers the missing piece most organizations overlook: composite alerts that detect anomalous runtime behavior in the application calling the LLM — unusual outbound destinations, abnormal token-consumption spikes, sudden secret access patterns, or compromised containers attempting to reach LLM APIs. This is where prompt-injection-driven actions become observable as workload anomalies.

### Other best-of-breed vendors at this layer

- **AI-native LLM firewalls / guardrails (specialist category):** [Lakera Guard](https://www.lakera.ai/) (sub-50ms latency, used by Dropbox and major banks), [Prompt Security](https://www.prompt.security/), [HiddenLayer AISec](https://www.hiddenlayer.com/) (Gartner Cool Vendor for AI Security), [CalypsoAI](https://calypsoai.com/), [Robust Intelligence](https://www.robustintelligence.com/) (acquired by Cisco), [Protect AI](https://protectai.com/) (acquired by Palo Alto Networks 2025).
- **Adjacent emerging players:** [Operant AI](https://www.operant.ai/), [Aiceberg](https://www.aiceberg.ai/), [Acuvity](https://acuvity.ai/), [HydroX AI](https://www.hydrox.ai/), [NeuralTrust](https://neuraltrust.ai/), [Pillar Security](https://www.pillar.security/), [Enkrypt AI](https://www.enkryptai.com/).
- **CSP-native model protections:** [Azure AI Content Safety](https://azure.microsoft.com/en-us/products/ai-services/ai-content-safety) (Prompt Shields), [AWS Bedrock Guardrails](https://aws.amazon.com/bedrock/guardrails/), [Google Cloud Model Armor](https://cloud.google.com/security/products/model-armor) — useful baselines but less complete than dedicated gateways.
- **Open source:** [NVIDIA NeMo Guardrails](https://github.com/NVIDIA/NeMo-Guardrails), [Garak LLM vulnerability scanner](https://github.com/leondz/garak) (testing), [PyRIT](https://github.com/Azure/PyRIT) (Microsoft's red-team toolkit).

---

## Layer 3 — The RAG Pipeline

Retrieval-Augmented Generation is where most enterprise GenAI lives today. It is also where data governance failures hit hardest, because the model is now actively reading from your most sensitive systems.

### The main risks

- **Permission bypass and over-broad retrieval.** The indexer often runs with admin scope across SharePoint, Confluence, Drive, and CRM. A junior employee asks a casual question and receives executive comp data. The single most common — and most damaging — enterprise RAG failure.
- **Indirect prompt injection through the knowledge base.** Research published at **USENIX Security 2025** demonstrated that as few as **5 carefully crafted documents** can manipulate AI responses with over 90% success in a knowledge base of millions.
- **Sensitive data sprawl and embedding inversion.** The **ALGEN framework (February 2025)** showed that with just 1,000 alignment samples, attackers can reconstruct 50–70% of original input text from leaked embeddings.

### Recent attacks

- **OWASP LLM08:2025 — Vector and Embedding Weaknesses (formalized 2025).** OWASP added a dedicated Top-10 entry recognizing the vector layer as a distinct attack surface.
- **ConfusedPilot attack (2024–2025).** Researchers at the University of Texas demonstrated that placing crafted documents inside a Microsoft 365 Copilot-indexed SharePoint site could manipulate Copilot's answers across an entire enterprise — no model access required.
- **EchoLeak's RAG dimension (June 2025).** Beyond Layer 2, EchoLeak (CVE-2025-32711) is fundamentally a RAG attack: the model retrieved content from a context source with no integrity check.

### Where Fortinet fits

- **[FortiCASB](https://www.fortinet.com/products/casb/forticasb) and [SSPM (in FortiSASE)](https://www.fortinet.com/products/sase)** govern the SaaS sources feeding RAG pipelines (Microsoft 365, Google Workspace, Salesforce). They catch over-shared SharePoint sites, exposed Drive folders, and risky OAuth apps **before** they get indexed — addressing the root cause of permission-bypass failures.
- **[FortiCNAPP DSPM](https://www.fortinet.com/products/forticnapp)** discovers and classifies sensitive data flowing into vector stores hosted on S3, Azure Blob, or managed services like OpenSearch and Pinecone — surfacing PII, PCI, and PHI sprawl in the embedding layer.
- **[FortiSandbox](https://www.fortinet.com/products/fortisandbox)** plays a critical role at ingestion. Documents entering a RAG pipeline — PDFs, Office files, support attachments — are exactly the kind of content traditional malware scanning misses when they carry embedded instructions, weaponized macros, or steganographic payloads. FortiSandbox provides **dynamic file analysis in a detonation environment**, identifying malicious behavior, hidden scripts, and prompt-injection payloads **before** they reach the vector store.
- **[FortiWeb](https://www.fortinet.com/products/web-application-firewall/fortiweb)** protects the RAG application's ingestion and query APIs with schema enforcement.
- **[FortiAIGate](https://www.fortinet.com/products/fortiaigate)** complements this layer by enforcing guardrails on the prompts assembled from retrieved content, catching indirect injection at the model boundary.

### Other best-of-breed vendors at this layer

- **CASB / SSPM:** [Netskope One](https://www.netskope.com/) (perennial CASB leader), [Zscaler](https://www.zscaler.com/), [Microsoft Defender for Cloud Apps](https://www.microsoft.com/en-us/security/business/siem-and-xdr/microsoft-defender-cloud-apps), [Palo Alto Prisma Access SaaS Security](https://www.paloaltonetworks.com/sase/casb), [Obsidian Security](https://www.obsidiansecurity.com/) (SSPM-focused), [Reco AI](https://www.reco.ai/) (SSPM with strong GenAI exposure detection).
- **DSPM specialists (dedicated, deeper than CNAPP bundles):** [Cyera](https://www.cyera.io/), [BigID](https://bigid.com/), [Sentra](https://www.sentra.io/), [Dig Security](https://www.dig.security/) (acquired by Palo Alto Networks 2023).
- **Document and content sandboxing:** [OPSWAT MetaDefender](https://www.opswat.com/products/metadefender), [Votiro](https://votiro.com/), [Glasswall](https://www.glasswall.com/) — peer technologies to FortiSandbox specifically for content disarmament before RAG ingestion.
- **RAG-aware security tooling (emerging):** [Lakera Guard for RAG](https://www.lakera.ai/), [Cranium AI](https://www.cranium.ai/), [Securiti AI](https://securiti.ai/) — early movers in retrieval-pipeline-specific protection.

---

## Layer 4 — The MCP Integration Layer

The Model Context Protocol lets models read from and act on external tools — file systems, databases, GitHub, Slack, Jira. Even in non-agentic usage, MCP opens a substantial new attack surface most teams underestimate.

### The main risks

- **Malicious or compromised MCP servers** with broad local privileges.
- **Credential and token sprawl** — long-lived OAuth tokens and API keys, almost always over-scoped.
- **Loss of auditability** — most MCP implementations log poorly, breaking SOC 2 and ISO accountability.

### Recent attacks

- **EscapeRoute — CVE-2025-53109 / CVE-2025-53110, Anthropic Filesystem MCP Server (July 2025).** Cymulate disclosed chained path-prefix and symlink bypasses leading to full host compromise. ([Cymulate disclosure](https://cymulate.com/blog/cve-2025-53109-53110-escaperoute-anthropic/))
- **CVE-2025-6514 — mcp-remote RCE (July 2025, CVSS 9.6).** JFrog disclosed a critical flaw: connecting to a malicious remote MCP server triggered arbitrary OS command execution on the client. ([JFrog write-up](https://jfrog.com/blog/2025-6514-critical-mcp-remote-rce-vulnerability/))
- **CVE-2025-65719 — Kubectl MCP Server RCE (January 2026).** OX Security disclosed a critical RCE: visiting a malicious website while the Kubectl MCP Server was running gave full control of both the local machine and every Kubernetes cluster the victim had access to. ([OX Security disclosure](https://www.ox.security/blog/cve-2025-65719-critical-rce-in-kubectl-mcp-server/))
- **CVE-2025-53967 — Framelink Figma MCP Server RCE (October 2025).** Imperva disclosed an RCE affecting thousands of design and developer workstations. ([Imperva disclosure](https://www.imperva.com/blog/another-critical-rce-discovered-in-a-popular-mcp-server/))

### Where Fortinet fits

- **[FortiGate VM](https://www.fortinet.com/products/private-cloud-security/fortigate-virtual-appliances)** inspects outbound traffic from MCP servers making network calls — a useful chokepoint when MCP servers run inside corporate networks or cloud environments. Fortinet has documented specific guidance for **[selective control of GenAI/LLM traffic egressing through FortiGate](https://community.fortinet.com/t5/FortiGate/Technical-Guide-Selective-control-of-Generative-AI-LLM-traffic/ta-p/405240)**.
- **[FortiCNAPP](https://www.fortinet.com/products/forticnapp)** detects MCP server processes, flags over-privileged service accounts, and surfaces runtime anomalies via behavioral baselines.
- **[FortiCASB / SSPM](https://www.fortinet.com/products/casb/forticasb)** maintains visibility into OAuth tokens MCP servers hold against SaaS apps, enabling revocation and rotation at scale.
- **[FortiSandbox](https://www.fortinet.com/products/fortisandbox)** dynamically analyzes MCP server npm/PyPI packages and container images before deployment.

### Other best-of-breed vendors at this layer

- **MCP-specific gateways and governance:** [Lunar.dev MCPX](https://www.lunar.dev/) (granular tool-level RBAC), [Docker MCP Gateway and Toolkit](https://www.docker.com/products/mcp-catalog-and-toolkit/) (container-boundary isolation), [Enkrypt AI MCP Security](https://www.enkryptai.com/solutions/mcp-security), [Invariant Labs](https://invariantlabs.ai/) (MCP runtime monitoring and prompt-injection detection), [TrueFoundry MCP Gateway](https://www.truefoundry.com/), [MintMCP](https://www.mintmcp.com/), [Composio](https://composio.dev/).
- **MCP code/config scanning:** [Backslash Open](https://www.backslash.security/), [Pillar Security](https://www.pillar.security/).
- **AI agent observability adjacent to MCP:** [Zenity](https://zenity.io/) (Gartner Representative Vendor for AI TRiSM), [CalypsoAI](https://calypsoai.com/), [Lasso Security](https://www.lasso.security/).
- **CSP-native partial coverage:** AWS IAM Identity Center, Azure Entra ID Conditional Access — used to constrain MCP-server OAuth scopes but not MCP-aware.

---

## Layer 5 — The Cloud and Model Infrastructure

The foundation. Easy to overlook, never the right thing to skip.

### The main risks

- **IAM misconfiguration on model endpoints** — wildcarded invoke permissions, cross-account role chains, missing condition keys.
- **Runtime compromise of self-hosted inference** — container escape, model weight theft, pickle-deserialization RCE.
- **Compliance and audit gaps** — prompt and completion logs holding the most sensitive enterprise data, often ungoverned.

### Recent attacks

- **Hugging Face malicious model uploads (ongoing through 2024–2025).** JFrog, ReversingLabs, and Protect AI documented hundreds of malicious models using pickle deserialization to achieve code execution on load.
- **AWS Bedrock invoke-permission incidents (2024–2025).** Over-permissive `bedrock:InvokeModel*` IAM policies let unintended principals invoke frontier models, generating five- and six-figure unauthorized bills before detection.
- **PyTorch pickle-deserialization RCE in model artifacts (well-documented 2024–2025).** PickleScan and similar tools identified active malicious payloads in `.bin` files in public registries.

### Where Fortinet fits

- **[FortiCNAPP](https://www.fortinet.com/products/forticnapp)** delivers CSPM, CWPP, and CIEM across AWS, Azure, GCP, and OCI — covering IAM misconfigurations on AI services, runtime protection for GPU and inference workloads, IaC scanning for Terraform and CloudFormation, and compliance reporting against CIS, NIST, ISO frameworks.
- **[FortiGate VM](https://www.fortinet.com/products/private-cloud-security/fortigate-virtual-appliances)** segments model-serving subnets from data planes, with east-west enforcement.
- **[FortiSandbox](https://www.fortinet.com/products/fortisandbox)** detonates model artifacts and container images pulled from public registries before they reach inference clusters.
- **[FortiAnalyzer](https://www.fortinet.com/products/management/fortianalyzer)** centralizes logs from FortiGate, FortiWeb, FortiAIGate, FortiCNAPP, and FortiCASB — giving the SOC a single pane of glass for AI events alongside everything else.

### Other best-of-breed vendors at this layer

- **CNAPP leaders (Gartner / PeerSpot 2026):** [Wiz](https://www.wiz.io/) (Google acquisition pending, ~$32B), [Palo Alto Prisma Cloud / Cortex Cloud](https://www.paloaltonetworks.com/prisma/cloud), [CrowdStrike Falcon Cloud Security](https://www.crowdstrike.com/products/cloud-security/), [Microsoft Defender for Cloud](https://www.microsoft.com/en-us/security/business/cloud-security/microsoft-defender-cloud), [SentinelOne Singularity Cloud Security](https://www.sentinelone.com/platform/cloud-security/), [Orca Security](https://orca.security/), [Check Point CloudGuard](https://www.checkpoint.com/cloudguard/), [Sysdig Secure](https://sysdig.com/), [Aqua Security](https://www.aquasec.com/).
- **AI-SPM and AI supply chain security specialists:** [HiddenLayer AISec Platform](https://www.hiddenlayer.com/) (Gartner Cool Vendor; 48+ CVEs disclosed in ML frameworks; AIBOM generation), [Protect AI](https://protectai.com/) (acquired by Palo Alto Networks 2025; model scanning, ML pipeline security, AI-BOM, red teaming), [Cranium AI](https://www.cranium.ai/), [Lasso Security](https://www.lasso.security/).
- **Model registry and supply chain:** [JFrog](https://jfrog.com/) (PickleScan and model artifact scanning), [ReversingLabs](https://www.reversinglabs.com/), [Sonatype](https://www.sonatype.com/), [Snyk](https://snyk.io/).
- **CSP-native:** [AWS Security Hub](https://aws.amazon.com/security-hub/), [Azure Defender for Cloud AI workload protection](https://www.microsoft.com/en-us/security/business/cloud-security/microsoft-defender-cloud), [GCP Security Command Center](https://cloud.google.com/security/products/security-command-center) — often used in combination with a third-party CNAPP rather than standalone.
- **Sandboxing peers:** [Palo Alto WildFire](https://www.paloaltonetworks.com/network-security/wildfire), [Check Point SandBlast](https://www.checkpoint.com/quantum/threat-emulation/), [Trellix Advanced Threat Defense](https://www.trellix.com/products/atd/), [VMRay](https://www.vmray.com/) — peer dynamic-analysis platforms.

---

## A simple way to think about it

Collapsed into one sentence for a CISO conversation:

> **GenAI changes where untrusted input enters your systems, what your applications do with model output, and how data and credentials surround the model. Everything else is a variation on those three themes.**

### Layer summary

| Layer | Attack surface added | Primary Fortinet coverage | Notable third-party vendors |
|---|---|---|---|
| **1. Developer Endpoint** | Insecure code, data leakage, supply chain, lateral movement | [FortiSASE](https://www.fortinet.com/products/sase), [FortiClient/FortiEDR](https://www.fortinet.com/products/endpoint-security/forticlient), [FortiCNAPP](https://www.fortinet.com/products/forticnapp) (DSPM + IaC + code), ZTNA (FortiGate + FortiAuthenticator) | Snyk, Checkmarx, Veracode, GHAS, Tabnine, MintMCP, Backslash |
| **2. LLM API Consumption** | Prompt injection, output handling, cost DoS, runtime anomalies | **[FortiAIGate](https://www.fortinet.com/products/fortiaigate)**, [FortiWeb/FortiAppSec](https://www.fortinet.com/products/web-application-firewall/fortiweb), [FortiGate VM](https://www.fortinet.com/products/private-cloud-security/fortigate-virtual-appliances), [FortiCNAPP](https://www.fortinet.com/products/forticnapp) runtime detection | Lakera, Prompt Security, HiddenLayer, CalypsoAI, Protect AI, Robust Intelligence, NeMo Guardrails |
| **3. RAG Pipeline** | Permission bypass, KB poisoning, embedding leakage, data sprawl | [FortiCASB/SSPM](https://www.fortinet.com/products/casb/forticasb), [FortiCNAPP DSPM](https://www.fortinet.com/products/forticnapp), **[FortiSandbox](https://www.fortinet.com/products/fortisandbox)**, [FortiWeb](https://www.fortinet.com/products/web-application-firewall/fortiweb), [FortiAIGate](https://www.fortinet.com/products/fortiaigate) | Netskope, Microsoft Defender for Cloud Apps, Obsidian, Cyera, BigID, Sentra, OPSWAT, Votiro |
| **4. MCP Integration** | Server compromise, token sprawl, audit gaps | [FortiGate VM](https://www.fortinet.com/products/private-cloud-security/fortigate-virtual-appliances), [FortiCNAPP](https://www.fortinet.com/products/forticnapp), [FortiCASB/SSPM](https://www.fortinet.com/products/casb/forticasb), [FortiSandbox](https://www.fortinet.com/products/fortisandbox) | Lunar.dev MCPX, Docker MCP Toolkit, Enkrypt AI, Invariant Labs, TrueFoundry, Zenity |
| **5. Cloud & Model Infra** | IAM misconfig, runtime compromise, model supply chain, compliance | [FortiCNAPP](https://www.fortinet.com/products/forticnapp), [FortiGate VM](https://www.fortinet.com/products/private-cloud-security/fortigate-virtual-appliances), [FortiSandbox](https://www.fortinet.com/products/fortisandbox), [FortiAnalyzer](https://www.fortinet.com/products/management/fortianalyzer) | Wiz, Prisma Cloud, CrowdStrike, Defender for Cloud, SentinelOne, Orca, HiddenLayer, Protect AI |

---

## Where Fortinet differentiates in this landscape

This is the honest PreSales view across the layers above:

- **Convergence over point products.** Most third-party vendors above are deep in one layer. The [Fortinet Security Fabric](https://www.fortinet.com/solutions/enterprise-midsize-business/security-fabric) — anchored by [FortiCNAPP](https://www.fortinet.com/products/forticnapp), [FortiAIGate](https://www.fortinet.com/products/fortiaigate), [FortiSASE](https://www.fortinet.com/products/sase), [FortiGate](https://www.fortinet.com/products/private-cloud-security/fortigate-virtual-appliances), [FortiWeb](https://www.fortinet.com/products/web-application-firewall/fortiweb), [FortiCASB](https://www.fortinet.com/products/casb/forticasb), [FortiSandbox](https://www.fortinet.com/products/fortisandbox), and [FortiAnalyzer](https://www.fortinet.com/products/management/fortianalyzer) — covers all five with a single telemetry, policy, and operations model.
- **FortiAIGate as a first-class AI runtime control plane.** Few network-security incumbents have shipped a purpose-built LLM gateway; Fortinet has.
- **The Security Fabric story.** A single dashboard from endpoint to LLM gateway to cloud workload to SaaS is operationally meaningful in an environment where the threat now spans all of those tiers.

Customers still combine Fortinet with best-of-breed where it makes sense: an LLM-firewall specialist for the deepest prompt-injection coverage, a dedicated DSPM where data classification is the dominant investment, or an AI-SPM tool such as HiddenLayer for granular model-supply-chain governance. The point is the conversation is no longer Fortinet **or** these vendors — it is the right combination, with Fortinet providing the converged backbone.

---

## Closing thought

GenAI security is not a single product problem and it is not a single team problem. It crosses the developer's laptop, the application tier, the data pipeline, the integration layer, and the cloud foundation.

What it asks of us is the same thing every wave of cloud transformation has asked: **defense in depth, applied with intention, measured against real outcomes**. The [Fortinet Security Fabric](https://www.fortinet.com/solutions/enterprise-midsize-business/security-fabric) — now extended with [FortiAIGate](https://www.fortinet.com/products/fortiaigate) as the AI-runtime control plane — was built exactly for that kind of work, unifying visibility, posture, and enforcement across the layers that GenAI now spans.

If you are designing a new GenAI workload, or retrofitting governance onto one already in production, start with the layer that worries you most, and work outward from there. The threats are new. The discipline is not.

---

## References

**Industry standards and frameworks**
- [OWASP Top 10 for LLM Applications (2025)](https://genai.owasp.org/)
- [OWASP LLM01:2025 — Prompt Injection](https://genai.owasp.org/llmrisk/llm01-prompt-injection/)
- OWASP LLM08:2025 — Vector and Embedding Weaknesses
- [NIST AI Risk Management Framework](https://www.nist.gov/itl/ai-risk-management-framework)
- [MITRE ATLAS](https://atlas.mitre.org/)

**Layer 1 — Developer Endpoint**
- [Pillar Security, "Rules File Backdoor" disclosure, March 2025](https://www.pillar.security/blog/new-vulnerability-in-github-copilot-and-cursor-how-hackers-can-weaponize-code-agents)
- [byteiota, "IDEsaster" — 24+ CVEs across AI IDEs, December 2025](https://byteiota.com/ai-ide-security-crisis-30-flaws-expose-cursor-copilot/)
- CVE-2025-54135 / CVE-2025-54136 — Cursor MCP RCE, August 2025
- [Docker, "AI Coding Agent Horror Stories," February 2026](https://www.docker.com/blog/ai-coding-agent-horror-stories-security-risks/)

**Layer 2 — LLM API Consumption**
- [Aim Labs, EchoLeak (CVE-2025-32711) analysis](https://arxiv.org/pdf/2509.10540)
- [NSFOCUS, ChatGPT Connector prompt injection incidents, August 2025](https://nsfocusglobal.com/prompt-word-injection-an-analysis-of-recent-llm-security-incidents/)
- [Fortinet, "FortiAIGate: Optimizing and Protecting AI Workloads," March 2026](https://www.fortinet.com/blog/security-operations/fortiaigate-optimizing-and-protecting-ai-workloads)
- [TechTarget, "LLM firewalls emerge as a new AI security layer," February 2026](https://www.techtarget.com/searchsecurity/feature/LLM-firewalls-emerge-as-a-new-AI-security-layer)

**Layer 3 — RAG Pipeline**
- USENIX Security 2025 — RAG poisoning research ("5 documents, 90% success")
- ALGEN embedding inversion framework, February 2025
- ConfusedPilot research on SharePoint-indexed Copilot manipulation
- [DSPM vendor landscape analysis, vCSO.ai 2026](https://vcso.ai/learn/best-dspm-tools-2026/)

**Layer 4 — MCP Integration**
- [Cymulate, EscapeRoute (CVE-2025-53109 / CVE-2025-53110), July 2025](https://cymulate.com/blog/cve-2025-53109-53110-escaperoute-anthropic/)
- [JFrog, mcp-remote RCE (CVE-2025-6514, CVSS 9.6), July 2025](https://jfrog.com/blog/2025-6514-critical-mcp-remote-rce-vulnerability/)
- [OX Security, Kubectl MCP Server RCE (CVE-2025-65719), January 2026](https://www.ox.security/blog/cve-2025-65719-critical-rce-in-kubectl-mcp-server/)
- [Imperva, Framelink Figma MCP Server RCE (CVE-2025-53967), October 2025](https://www.imperva.com/blog/another-critical-rce-discovered-in-a-popular-mcp-server/)
- [Red Hat, "MCP security: The current situation," February 2026](https://www.redhat.com/en/blog/mcp-security-current-situation)
- [Fortinet community guide on selective control of GenAI/LLM traffic via FortiGate](https://community.fortinet.com/t5/FortiGate/Technical-Guide-Selective-control-of-Generative-AI-LLM-traffic/ta-p/405240)

**Layer 5 — Cloud & Model Infrastructure**
- [PeerSpot CNAPP Top Vendors, 2026](https://www.peerspot.com/categories/cloud-native-application-protection-platforms-cnapp)
- [HiddenLayer AISec Platform 2.0 launch, RSAC 2025](https://hiddenlayer.com/innovation-hub/hiddenlayer-unveils-aisec-platform-2-0-to-deliver-unmatched-context-visibility-and-observability-for-enterprise-ai-security/)
- [aithority, "Top AI Supply Chain Security Vendors of 2026"](https://aithority.com/guest-authors/the-top-ai-supply-chain-security-vendors-of-2026/)
- [Wiz Academy, "Top AI Security Tools for the Cloud"](https://www.wiz.io/academy/ai-security/ai-security-tools)

**Fortinet portfolio (full hyperlink set)**
- [Fortinet AI Security Solutions](https://www.fortinet.com/solutions/ai-security)
- [Fortinet Security Fabric](https://www.fortinet.com/solutions/enterprise-midsize-business/security-fabric)
- [FortiAIGate](https://www.fortinet.com/products/fortiaigate)
- [FortiCNAPP](https://www.fortinet.com/products/forticnapp)
- [FortiWeb](https://www.fortinet.com/products/web-application-firewall/fortiweb)
- [FortiAppSec Cloud](https://www.fortinet.com/products/web-application-firewall/fortiappsec-cloud)
- [FortiGate VM](https://www.fortinet.com/products/private-cloud-security/fortigate-virtual-appliances)
- [FortiSASE](https://www.fortinet.com/products/sase)
- [FortiCASB](https://www.fortinet.com/products/casb/forticasb)
- [FortiSandbox](https://www.fortinet.com/products/fortisandbox)
- [FortiClient](https://www.fortinet.com/products/endpoint-security/forticlient)
- [FortiEDR](https://www.fortinet.com/products/endpoint-security/fortiedr)
- [FortiAuthenticator](https://www.fortinet.com/products/identity-access-management/fortiauthenticator)
- [FortiAnalyzer](https://www.fortinet.com/products/management/fortianalyzer)
- [Fortinet Product Catalog](https://www.fortinet.com/products)

---

** Written from a Fortinet PreSales engineering perspective. The views and architectural interpretations presented here are intended for technical discussion, solution positioning, and security strategy alignment purposes only, and may evolve as AI security capabilities and vendor implementations mature. For deeper dives — including reference architectures, threat-to-control mapping, competitive positioning, implementation guidance, or PoC planning — engage your Fortinet account team or Fortinet Systems Engineering representatives.

This material contains proprietary concepts, positioning, and technical guidance intended solely for the original audience. Redistribution, reproduction, modification, external publication, or reuse of this content — in whole or in part — without prior written consent from  Fortinet￼ is prohibited. **

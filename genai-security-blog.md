# Securing the GenAI Stack: A Layered Look at the Attack Surface — and How Fortinet Helps

*From the developer's laptop to the LLM endpoint in your cloud, GenAI has quietly redrawn the enterprise attack surface. Here is a clean, practical view of what's changed, real attacks already happening at each layer, and where the Fortinet Security Fabric fits in.*

---

## Why this matters now

Generative AI is no longer a side project. Developers are "vibe coding" with Copilot and Cursor, applications are calling LLM APIs at runtime, knowledge bases are being indexed into vector stores for RAG, and the Model Context Protocol (MCP) is connecting models to live tools and data sources.

Each of these shifts introduces a new layer of risk. And like any new architecture, GenAI does not replace the security fundamentals — it **stacks new concerns on top of them**.

This post walks through the five layers of a typical GenAI deployment, the main risks at each layer, recent real-world incidents to make the threats concrete, and how the Fortinet portfolio maps cleanly to each layer. No agentic AI here — we are keeping the scope to LLM consumption, RAG, and MCP integrations.

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

- **Insecure code at scale.** LLMs cheerfully suggest hardcoded secrets, weak crypto, missing input validation, and outdated dependencies. A December 2025 study of open-source pull requests found AI-generated code introduces **2.74x more security vulnerabilities** than human-written code.
- **Sensitive data leaving the boundary.** Developers paste `.env` files, customer PII, or proprietary source into public LLM interfaces. Once submitted, it is gone.
- **Slopsquatting.** Attackers register the package names that LLMs hallucinate (`fast-json-parser-v2`, `aws-sdk-lite`). Research shows commercial models hallucinate ~5% of suggested packages; open-source models up to ~22%.

### Recent attacks

- **"Rules File Backdoor" — Pillar Security (March 2025).** Attackers embed invisible Unicode instructions inside `.cursorrules` or Copilot configuration files. When developers pull a poisoned repo, the AI assistant silently generates backdoored code that looks legitimate during review. GitHub later added a Unicode-warning banner in May 2025 in response.
- **"IDEsaster" — 24 CVEs across AI IDEs (December 2025).** Researcher Ari Marzouk disclosed over 30 vulnerabilities across Cursor, Windsurf, GitHub Copilot, Zed.dev, Roo Code, and JetBrains Junie — including **CVE-2025-49150, CVE-2025-54130, CVE-2025-61590 (Cursor)** and **CVE-2025-53773 (GitHub Copilot, CVSS 7.8)**. The investigation found exploitable flaws in 100% of tested AI IDEs.
- **Cursor IDE RCE via MCP — CVE-2025-54135 / CVE-2025-54136 (August 2025).** An indirect prompt injection let attackers write a malicious `.cursor/mcp.json` configuration into the workspace, achieving persistent remote code execution across IDE restarts — no user interaction required.

### Where Fortinet fits

- **FortiSASE** discovers shadow AI usage and applies DLP policies on outbound LLM traffic, on-network or remote.
- **FortiClient / FortiEDR** enforces endpoint posture and blocks data exfiltration from developer machines.
- **FortiCNAPP — DSPM (Data Security Posture Management)** is critical here for a reason developers underestimate: when a vibe-coded application is deployed to cloud, it often hardcodes paths to S3 buckets, databases, or storage accounts containing sensitive data the developer never classified. DSPM continuously discovers sensitive data flowing through those AI-generated code paths and flags shadow data stores created by AI-suggested infrastructure.
- **FortiCNAPP IaC + code scanning** catches insecure generated code, hardcoded secrets, and slopsquatting-style dependency risks in CI/CD before merge.
- **ZTNA via FortiGate + FortiClient + FortiAuthenticator** matters because the developer endpoint is increasingly a privileged gateway into source repos, cloud consoles, and production data. ZTNA enforces per-application, identity-aware access — so a compromised AI extension or malicious MCP server on a developer laptop cannot freely lateral-move into production GitHub orgs, Kubernetes clusters, or cloud accounts. It replaces the implicit trust that VPN-era access models grant.

---

## Layer 2 — LLM API Consumption

When your application calls OpenAI, Anthropic, Bedrock, Vertex AI, or Azure OpenAI, you inherit a new flow of sensitive data leaving your perimeter — and a new untrusted input source coming back.

### The main risks

- **Prompt injection (direct and indirect).** OWASP ranks this as **LLM01:2025 — the #1 LLM risk**. Untrusted input overrides system instructions, often via content the model retrieves rather than content the user types.
- **Insecure output handling.** When model output is rendered as HTML, executed as code, or used in SQL, the LLM becomes a fresh vector for XSS, SSRF, and RCE.
- **Cost and availability impact.** Unbounded token consumption and adversarial long-context prompts drive runaway cloud spend. A leaked API key is now a financial DoS.

### Recent attacks

- **EchoLeak — CVE-2025-32711, Microsoft 365 Copilot (June 2025).** Disclosed by Aim Labs, this was the **first known zero-click prompt injection in a production LLM system**. An attacker sent a crafted email; Copilot, while summarizing the user's inbox, retrieved the email, executed the embedded instructions, and exfiltrated internal documents to an attacker-controlled server — with no user interaction. Microsoft issued an emergency patch.
- **ChatGPT Connector data leakage (July–August 2025).** NSFOCUS Security Lab documented multiple incidents where indirect prompt injection through ChatGPT's connectors (Google Drive, SharePoint, GitHub) exfiltrated API keys, login credentials, and confidential files. Any user processing untrusted documents through a connected workspace was exposed.
- **ChatGPT Windows product key leak (July 2025).** Researchers used a crafted "guessing game" prompt to bypass content filters and trick ChatGPT into revealing valid Windows product keys — including an enterprise license tied to a major bank — demonstrating that classic filter evasion is far from solved.

### Where Fortinet fits

- **FortiAIGate** is purpose-built for this layer. Deployed as a containerized LLM gateway between the application and the model (OpenAI, Anthropic, Bedrock, or self-hosted), it inspects every prompt and completion in real time, enforces guardrails against prompt injection and jailbreaking, prevents data exfiltration, blocks model theft and excessive token consumption, and provides per-interaction logging and cost tracking. It is the AI-aware control plane that traditional WAFs and API gateways were never designed to be.
- **FortiWeb / FortiAppSec Cloud** protects the HTTP layer in front of your LLM-powered APIs — schema enforcement, rate limiting, bot mitigation, and OWASP coverage on the application surface.
- **FortiGate VM** inspects outbound traffic to external LLM providers with application-control awareness for AI SaaS and DLP on payloads — useful for catching shadow AI usage by apps that bypass FortiAIGate.
- **FortiCNAPP runtime behavior detection** delivers the missing piece most organizations overlook: composite alerts that detect anomalous runtime behavior in the application calling the LLM — unusual outbound destinations, abnormal token-consumption spikes, sudden secret access patterns, or compromised containers attempting to reach LLM APIs. This is where prompt-injection-driven actions become observable as workload anomalies rather than as model behavior.
- **FortiCNAPP** continues to detect exposed API keys in source code, containers, and runtime workloads.

---

## Layer 3 — The RAG Pipeline

Retrieval-Augmented Generation is where most enterprise GenAI lives today. It is also where data governance failures hit hardest, because the model is now actively reading from your most sensitive systems.

### The main risks

- **Permission bypass and over-broad retrieval.** The indexer often runs with admin scope across SharePoint, Confluence, Drive, and CRM. A junior employee asks a casual question and receives executive compensation data. This is the single most common — and most damaging — enterprise RAG failure.
- **Indirect prompt injection through the knowledge base.** An attacker plants a poisoned document. When the model retrieves it, the malicious instructions execute as if they came from a trusted source. Research published at **USENIX Security 2025** demonstrated that as few as **5 carefully crafted documents** can manipulate AI responses with over 90% success in a knowledge base of millions.
- **Sensitive data sprawl and embedding inversion.** PII, PCI, and PHI flow into embeddings without classification. The **ALGEN framework (February 2025)** showed that with just 1,000 alignment samples, attackers can reconstruct 50–70% of original input text from leaked embeddings. Sharing embeddings is now functionally equivalent to sharing the source documents.

### Recent attacks

- **OWASP LLM08:2025 — Vector and Embedding Weaknesses (formalized 2025).** OWASP added a dedicated Top-10 entry for this category, recognizing that the vector layer is now a distinct, undertested attack surface — and prompted by a wave of academic and real-world demonstrations of embedding inversion, cross-tenant leakage, and similarity hijacking.
- **ConfusedPilot attack (2024–2025).** Researchers at the University of Texas demonstrated that placing crafted documents inside a Microsoft 365 Copilot-indexed SharePoint site could manipulate Copilot's answers across an entire enterprise. The attack required no model access — just write access to a shared drive that the indexer trusted.
- **EchoLeak's RAG dimension (June 2025).** While listed under Layer 2, EchoLeak (CVE-2025-32711) is fundamentally a RAG attack: the model retrieved an email it should not have trusted, and the retrieval pipeline had no integrity check on the content entering the context window.

### Where Fortinet fits

- **FortiCASB and SSPM** govern the SaaS sources that feed RAG pipelines (Microsoft 365, Google Workspace, Salesforce). They catch over-shared SharePoint sites, exposed Drive folders, and risky OAuth apps **before** they get indexed — addressing the root cause of permission-bypass failures.
- **FortiCNAPP DSPM** discovers and classifies sensitive data flowing into vector stores hosted on S3, Azure Blob, or managed services like OpenSearch and Pinecone — surfacing PII, PCI, and PHI sprawl in the embedding layer.
- **FortiSandbox** plays a critical and often-overlooked role at the ingestion stage. Documents entering a RAG pipeline — PDFs, Office files, support attachments, scanned forms — are exactly the kind of content traditional malware scanning misses when they carry embedded instructions, weaponized macros, or steganographic payloads. FortiSandbox provides **dynamic file analysis** in a detonation environment, identifying malicious behavior, hidden scripts, and prompt-injection payloads in files **before** they reach the vector store. Pairing FortiSandbox with the RAG ingestion gateway closes the door on KB poisoning at the front end.
- **FortiWeb** protects the RAG application's ingestion and query APIs, with schema enforcement preventing malformed or oversized inputs.
- **FortiAIGate** complements this layer by enforcing guardrails on the prompts assembled from retrieved content, catching indirect injection patterns at the model boundary.

---

## Layer 4 — The MCP Integration Layer

The Model Context Protocol lets models read from and act on external tools — file systems, databases, GitHub, Slack, Jira. Even when used in a non-agentic way, MCP opens a substantial new attack surface that most teams underestimate.

### The main risks

- **Malicious or compromised MCP servers.** The ecosystem is young, registries are unvetted, and most servers run with broad local privileges. Installing a typosquatted MCP server is like installing a malicious npm package with elevated scope.
- **Credential and token sprawl.** MCP servers hold long-lived OAuth tokens and API keys, almost always over-scoped, with no central inventory and no rotation discipline.
- **Loss of auditability.** Most MCP implementations log poorly. Organizations cannot answer the basic SOC 2 question of "which tool was called, by whom, against what data."

### Recent attacks

- **EscapeRoute — CVE-2025-53109 / CVE-2025-53110, Anthropic Filesystem MCP Server (July 2025).** Cymulate disclosed two chained vulnerabilities: a path-prefix validation bypass and a symlink check bypass. Together they let attackers read or modify any file on the host, including `/etc/sudoers`, leading to full system compromise. Patched in version 2025.7.1.
- **CVE-2025-6514 — mcp-remote RCE (July 2025, CVSS 9.6).** JFrog disclosed a critical flaw in the popular `mcp-remote` proxy used by Claude Desktop and other clients. Connecting to a malicious remote MCP server triggered arbitrary OS command execution on the client — the first real-world full-RCE on an MCP client from connecting to an untrusted server.
- **CVE-2025-65719 — Kubectl MCP Server RCE (January 2026).** OX Security disclosed a critical RCE where simply visiting a malicious website while the Kubectl MCP Server was running gave the attacker full control of both the local machine and **every Kubernetes cluster the victim had access to**. Affected all versions below 1.2.0.
- **CVE-2025-53967 — Framelink Figma MCP Server RCE (October 2025).** Imperva disclosed an RCE in the Figma MCP Server affecting thousands of design and developer workstations through a fallback-mechanism flaw.

### Where Fortinet fits

- **FortiGate VM** inspects outbound traffic from any MCP server making network calls — a useful chokepoint when MCP servers run inside corporate networks or cloud environments. Fortinet has also documented specific guidance for **selective control of GenAI/LLM traffic egressing from MCP clients and AI agents** through FortiGate.
- **FortiCNAPP** detects MCP server processes running in dev and production environments, flags over-privileged service accounts, and surfaces runtime anomalies on the hosts and containers where they live. Behavioral baselines catch the unusual fork-exec, file-touch, or outbound-call patterns that follow an MCP compromise.
- **FortiCASB / SSPM** maintains visibility into the OAuth tokens MCP servers hold against SaaS apps, so security teams can revoke and rotate at scale.
- **FortiSandbox** is highly relevant here too: MCP servers are often distributed as npm or PyPI packages whose installers can be dynamically analyzed before deployment in dev or production environments.

---

## Layer 5 — The Cloud and Model Infrastructure

The foundation. Easy to overlook, never the right thing to skip.

### The main risks

- **IAM misconfiguration on model endpoints.** Wildcarded invoke permissions on Bedrock, Vertex AI, or Azure OpenAI; cross-account role chains; missing condition keys.
- **Runtime compromise of self-hosted inference.** GPU nodes serving open-source models on EKS, AKS, or GKE face container escape, model weight theft, and the well-known pickle-deserialization RCE problem with artifacts pulled from public registries.
- **Compliance and audit gaps.** Prompt and completion logs contain the most sensitive data the organization handles — and are often under-governed, over-retained, and impossible to produce on demand for EU AI Act, NIST AI RMF, or ISO 42001 audits.

### Recent attacks

- **Hugging Face malicious model uploads (ongoing, accelerated through 2024–2025).** Multiple security vendors (JFrog, ReversingLabs, Protect AI) have documented hundreds of malicious models on Hugging Face using pickle deserialization to achieve code execution the moment a developer or inference platform loads the weights. The supply-chain risk is now mainstream.
- **AWS Bedrock invoke-permission incidents (2024–2025).** Multiple cloud security vendors reported customer environments where over-permissive `bedrock:InvokeModel*` IAM policies allowed unintended principals — including compromised CI runners — to invoke expensive frontier models, generating five- and six-figure unauthorized bills before detection.
- **Pickle-based RCE in PyTorch model artifacts (well-documented through 2024–2025).** PickleScan and similar tools have identified active malicious payloads in `.bin` files across public registries; the deserialization-on-load behavior makes the attack near-zero-click for anyone running inference on untrusted weights.

### Where Fortinet fits

- **FortiCNAPP** delivers CSPM, CWPP, and CIEM across AWS, Azure, GCP, and OCI — covering IAM misconfigurations on AI services, runtime protection for GPU and inference workloads, IaC scanning for Terraform and CloudFormation, and compliance reporting mapped to CIS, NIST, and ISO frameworks.
- **FortiGate VM** segments model-serving subnets from data planes, with east-west enforcement that contains a compromise to a single tier.
- **FortiSandbox** detonates model artifacts and container images pulled from public registries before they reach inference clusters.
- **FortiAnalyzer** centralizes logs from FortiGate, FortiWeb, FortiAIGate, FortiCNAPP, and FortiCASB — giving the SOC a single pane of glass for AI-related events alongside everything else.

---

## A simple way to think about it

If you collapse all of this into a sentence that lands with a CISO, it is this:

> **GenAI changes where untrusted input enters your systems, what your applications do with model output, and how data and credentials surround the model. Everything else is a variation on those three themes.**

That framing maps neatly across the layers, and it maps neatly across the Fortinet portfolio.

| Layer | What it adds to your attack surface | Primary Fortinet coverage |
|---|---|---|
| Developer Endpoint | Insecure code, data leakage, supply chain, lateral movement risk | FortiSASE, FortiClient, FortiCNAPP (DSPM + IaC + code scanning), ZTNA (FortiGate + FortiAuthenticator) |
| LLM API Consumption | Prompt injection, output handling, cost DoS, runtime anomalies | **FortiAIGate**, FortiWeb / FortiAppSec, FortiGate VM, FortiCNAPP runtime behavior detection |
| RAG Pipeline | Permission bypass, KB poisoning, embedding leakage, data sprawl | FortiCASB / SSPM, FortiCNAPP DSPM, **FortiSandbox** (file dynamic analysis), FortiWeb, FortiAIGate |
| MCP Integration | Server compromise, token sprawl, audit gaps | FortiGate VM, FortiCNAPP, FortiCASB / SSPM, FortiSandbox |
| Cloud & Model Infra | IAM misconfig, runtime compromise, model supply chain, compliance | FortiCNAPP, FortiGate VM, FortiSandbox, FortiAnalyzer |

---

## Closing thought

GenAI security is not a single product problem and it is not a single team problem. It crosses the developer's laptop, the application tier, the data pipeline, the integration layer, and the cloud foundation.

What it asks of us is the same thing every wave of cloud transformation has asked: **defense in depth, applied with intention, measured against real outcomes**. The Fortinet Security Fabric — now extended with FortiAIGate as the AI-runtime control plane — was built exactly for that kind of work, unifying visibility, posture, and enforcement across the layers that GenAI now spans.

If you are designing a new GenAI workload, or trying to retrofit governance onto one already in production, start with the layer that worries you most, and work outward from there. The threats are new. The discipline is not.

---

## References

**Layer 1 — Developer Endpoint**
- Pillar Security, "Rules File Backdoor" vulnerability disclosure, March 2025 — https://www.pillar.security/blog/new-vulnerability-in-github-copilot-and-cursor-how-hackers-can-weaponize-code-agents
- "IDEsaster" — 24+ CVEs across AI IDEs, December 2025 — https://byteiota.com/ai-ide-security-crisis-30-flaws-expose-cursor-copilot/
- CVE-2025-54135 / CVE-2025-54136 — Cursor MCP RCE, August 2025
- Docker Blog, "AI Coding Agent Horror Stories," February 2026 — https://www.docker.com/blog/ai-coding-agent-horror-stories-security-risks/

**Layer 2 — LLM API Consumption**
- Aim Labs, EchoLeak (CVE-2025-32711) zero-click exploit in M365 Copilot, June 2025 — https://arxiv.org/pdf/2509.10540
- NSFOCUS, ChatGPT Connector prompt injection incidents, July–August 2025 — https://nsfocusglobal.com/prompt-word-injection-an-analysis-of-recent-llm-security-incidents/
- OWASP LLM01:2025 — Prompt Injection — https://genai.owasp.org/llmrisk/llm01-prompt-injection/
- Fortinet, "FortiAIGate: Optimizing and Protecting AI Workloads," March 2026 — https://www.fortinet.com/blog/security-operations/fortiaigate-optimizing-and-protecting-ai-workloads

**Layer 3 — RAG Pipeline**
- USENIX Security 2025 — "5 documents, 90% attack success" RAG poisoning research
- OWASP LLM08:2025 — Vector and Embedding Weaknesses
- ALGEN embedding inversion framework, February 2025
- ConfusedPilot research on SharePoint-indexed Copilot manipulation

**Layer 4 — MCP Integration**
- Cymulate, EscapeRoute (CVE-2025-53109 / CVE-2025-53110), July 2025 — https://cymulate.com/blog/cve-2025-53109-53110-escaperoute-anthropic/
- JFrog, mcp-remote RCE (CVE-2025-6514, CVSS 9.6), July 2025 — https://jfrog.com/blog/2025-6514-critical-mcp-remote-rce-vulnerability/
- OX Security, Kubectl MCP Server RCE (CVE-2025-65719), January 2026 — https://www.ox.security/blog/cve-2025-65719-critical-rce-in-kubectl-mcp-server/
- Imperva, Framelink Figma MCP Server RCE (CVE-2025-53967), October 2025
- Fortinet community guide, "Selective control of GenAI/LLM traffic through FortiGate" — https://community.fortinet.com/t5/FortiGate/Technical-Guide-Selective-control-of-Generative-AI-LLM-traffic/ta-p/405240

**Layer 5 — Cloud & Model Infrastructure**
- Hugging Face malicious model research — JFrog, ReversingLabs, Protect AI (2024–2025)
- AWS Bedrock IAM misconfiguration patterns documented by CSPM vendors
- PickleScan and pickle-deserialization research on PyTorch model artifacts

**General**
- OWASP Top 10 for LLM Applications, 2025 — https://genai.owasp.org/

---

*Written from a Fortinet PreSales engineering perspective. For deeper dives — reference architectures, threat-to-control mapping, or PoC planning — reach out to your Fortinet team.*

# The State and Future of Experiential, Adaptive AI Cognition

**A deep research review — as of June 2026**

Scope: the convergence of (a) *adaptive / controllable test-time compute* — allocating
thinking effort to task difficulty — and (b) *experiential memory and self-evolution* —
agents that accumulate and reuse experience instead of re-deriving everything, with the
human dual-process (System 1 / System 2, habit, procedural memory) framing as the guiding
analogy. Plus the governance of systems that learn, and where high-impact funding should go.

> **Methodology & confidence note.** This report was produced by five parallel research
> agents fanning out across the web, arXiv, lab pages, and OpenReview, prioritizing late-2025
> → mid-2026 work. In this environment full-text fetching (WebFetch) was uniformly HTTP-403
> blocked, so every claim derives from search-result snippets that quote primary sources,
> cross-checked across multiple searches. **Confidence convention used throughout:** claims
> corroborated across ≥2 independent sources/agents are *High*; single-snippet or
> vendor-self-reported figures are *Medium*; 2026-dated arXiv IDs (the `26xx.xxxxx` series)
> whose PDFs could not be opened are *flagged unverified* — titles look right but specific
> numbers should be re-checked against the originals before any external use.

---

## 1. Executive summary

1. **Adaptive test-time compute is the most production-real part of this whole agenda.** Every
   major lab now ships a "thinking budget" knob (Google Gemini `thinkingBudget`, Anthropic
   Claude `budget_tokens` + "adaptive thinking", OpenAI `reasoning_effort`, Qwen3 thinking
   budgets, DeepSeek V3.1 hybrid Think/Non-Think, GPT-5's internal router). The open research
   recipe (Stanford's **s1** "budget forcing") and confidence-gated early exit (**DEER**) are
   reproducible and quantified.

2. **System-2 → System-1 distillation works for *easy* deliberation and fails for *hard*
   reasoning.** Meta FAIR's "Distilling System 2 into System 1" successfully internalizes
   several reasoning techniques — but reports its own **negative result**: multi-step
   chain-of-thought for hard math (GSM8K) does **not** distill into a single forward pass.
   That negative result is the standing open problem of the entire "make deliberation
   instinctive" vision.

3. **Experiential memory measurably helps agents — in narrow, verifiable domains.** Skill
   libraries (Voyager), verbal lessons (Reflexion/ExpeL), and induced workflows (Agent
   Workflow Memory: +51% relative on WebArena) are robustly replicated. Self-editing code
   agents (Darwin Gödel Machine 20→50% SWE-bench; SICA 17→53%) show large reported jumps —
   **but** a 2026 benchmark-integrity crisis (UC Berkeley RDI showed top agent benchmarks can
   be reward-hacked toward ~100%) means many self-improvement gains must be read skeptically.

4. **Memory drift, error accumulation, and long-horizon forgetting are the consensus open
   problems.** Stored experience deviates from ground truth under repeated summarization;
   bad memories propagate ("experience-following"); long-horizon agents still collapse from
   forgetting + planning failures (HORIZON benchmark). Sparse-memory finetuning (Meta/Berkeley)
   is the most quantified continual-learning result (forgetting cut from ~71–89% to ~11%).

5. **The governance-of-learning-systems intersection is a genuine white space — and the
   strongest fundable bet in this report.** Every mature regulatory regime (FDA PCCP, EU AI
   Act Art. 43(4), pharma GAMP 5 / "validated state", finance SR 11-7) handles "self-learning"
   AI the same way: by *forbidding uncontrolled self-modification* — adaptation is legal only
   if pre-specified and bounded. None has a positive framework for an agent that silently
   rewrites its own behavior from accumulated experience. A fast-growing 2025–26 academic
   literature on self-evolving agents and agent drift exists, but is almost entirely
   disconnected from validation/CSV machinery. The one paper bridging adaptive agents to EU
   law (arXiv:2604.04604) has **no GxP/pharma, FDA-device, or finance equivalent.**

---

## 2. Current state, by sub-area

### 2.1 Adaptive / controllable test-time compute

**What genuinely works (High confidence):**

- **Budget forcing — `s1`** (Muennighoff, Yang, … Hashimoto; Stanford/UW/AI2; arXiv:2501.19393,
  Jan 2025, EMNLP 2025). SFT on 1,000 curated traces over Qwen2.5-32B + forcing more/less
  "thinking" by suppressing or appending the stop token ("Wait"). Outperforms o1-preview by
  up to **27%** on competition math; gains flatten ~6×. The reference recipe for the subfield.
- **RL length control — `L1` / LCPO** (Aggarwal, Welleck; CMU; arXiv:2503.04697, Mar 2025).
  Dual reward (correctness + length adherence). A 1.5B model matches **GPT-4o at equal
  generation length**; up to ~150% relative gain over s1's length control.
- **Confidence-gated early exit — `DEER`** (IIE-CAS/UCAS + Huawei; arXiv:2504.15895, Apr 2025).
  *Training-free.* Cuts reasoning length **31–43%** while *improving* accuracy **+1.7–5.7%** on
  MATH-500/AIME — the closest thing to a free lunch in the area.
- **Routing & cascades — `RouteLLM`** (LMSYS/UC Berkeley; arXiv:2406.18665, ICLR 2025).
  ~**95%** of GPT-4 quality using ~**14%** strong-model calls → ~75–85% cost reduction.
- **Shipped vendor budgets:** Gemini 2.5 `thinkingBudget` (0–24,576 tokens; `-1` = dynamic);
  Claude `budget_tokens` + dedicated "Adaptive thinking" docs; OpenAI `reasoning_effort`
  (minimal→high); Qwen3 `/think` `/no_think` + thinking budget; DeepSeek V3.1 hybrid modes;
  GPT-5 internal router. This is the single most real-world-validated form of adaptive compute.

**Aspirational / contested:**

- "More budget = better" is false past a point — *Increasing the Thinking Budget is Not All
  You Need* (arXiv:2512.19585, Dec 2025); s1's gains flatten ~6×.
- Latent/continuous implicit-CoT (CODI, System-1.5, KaVa, 2025) is promising but early.
- Per-query difficulty estimation (what routing and "think-when-needed" both depend on)
  remains brittle; cost-aware evaluation methodology is itself unsettled (*The Price of a
  Second Thought*, arXiv:2505.22017).

### 2.2 System-2 → System-1 distillation

- **Distilling System 2 into System 1** (Yu, Xu, **Weston**, Kulikov; Meta FAIR;
  arXiv:2407.06023, Jul 2024). Run a System-2 method, discard intermediate tokens, fine-tune
  to emit the final answer directly. Works for Rephrase-and-Respond, System-2-Attention,
  Branch-Solve-Merge. **Does not work for GSM8K-style multi-step math (explicit negative
  result).**
- Implicit-CoT lineage: Deng/Choi/Shieber — *Implicit CoT via Knowledge Distillation*
  (arXiv:2311.01460), *Stepwise Internalization* (arXiv:2405.14838); newer latent variants
  CODI (2502.21074), System-1.5 (2505.18962), KaVa (2510.02312).
- **Sleep-time compute** (Lin, Snell, … Stoica, Gonzalez; Berkeley/Letta; arXiv:2504.13171,
  Apr 2025) reframes the axis: pre-compute over context *offline* to cut test-time cost ~5×.

### 2.3 Procedural / episodic / experiential memory architectures

| System | Memory type | Key result / role | Cite |
|---|---|---|---|
| Reflexion (2023) | episodic verbal "lessons from failure" | canonical verbal-RL retry loop | 2303.11366 |
| Generative Agents (2023) | memory stream + reflection + relevance/recency/importance retrieval | reference episodic+reflective design | 2304.03442 |
| Voyager (2023) | **procedural skill library** (executable code, NL-indexed) | canonical "muscle memory" / lifelong skills | 2305.16291 |
| ExpeL (AAAI 2024) | extracted NL insights from trajectories | experiential learning w/o weight updates | 2308.10144 |
| MemGPT → Letta (2023) | OS-style virtual memory paging | "LLM as OS"; productized | 2310.08560 |
| Agent Workflow Memory (2024) | induced reusable **workflows** | **+51.1% rel. WebArena**, +24.6% Mind2Web | 2409.07429 |
| A-MEM (2025) | Zettelkasten dynamic linking/evolution | agent-authored, self-linking notes | 2502.12110 |
| Mem0 (ECAI 2025) | scalable long-term + graph memory | ~26% over OpenAI memory on LOCOMO (vendor-run) | 2504.19413 |

The field has converged on a **forms / functions / dynamics** taxonomy (Fudan/RUC 47-author
survey, arXiv:2512.13564, Dec 2025) ≈ the classic **episodic / semantic / procedural** split.

### 2.4 Self-evolving agent frameworks

- **ADAS** (Hu, Lu, Clune; UBC/Vector; arXiv:2408.08435, ICLR 2025) — meta-agent programs new
  agents; *but the meta-agent itself is fixed*.
- **Gödel Agent** (arXiv:2410.04444, ACL 2025) — agent modifies its own logic.
- **SICA** (Bristol/iGent AI; arXiv:2504.15228) — agent edits its **own codebase**; 17→53%
  SWE-bench Verified subset.
- **Darwin Gödel Machine** (Sakana AI/UBC/Vector; arXiv:2505.22954, May 2025) — evolutionary
  archive of self-modifying variants; **SWE-bench 20→50%, Polyglot 14→31%**; authors flag
  self-rewriting-code safety concerns.
- **ReasoningBank + MaTTS** (Google + UIUC; arXiv:2509.25140, Sep 2025) — the key **bridge**
  paper linking agent memory to test-time scaling (memory-aware test-time scaling).
- Survey anchor: *A Survey of Self-Evolving Agents: On Path to ASI* (Princeton/UIUC; **Mengdi
  Wang, Heng Ji** et al.; arXiv:2507.21046, Jul 2025) — *what/when/how/where to evolve*.

### 2.5 Negative transfer, memory drift, the parametric-vs-external debate

- **Experience-following failure modes** (arXiv:2505.16067) — *error propagation* + *misaligned
  replay*; mitigated by evaluator-gated add/delete.
- **Catastrophic forgetting:** *Sparse Memory Finetuning* (Jessy Lin et al.; Berkeley/Meta;
  arXiv:2510.15103, Oct 2025) — NaturalQuestions F1 drop after learning new facts: full FT
  −89%, LoRA −71%, **sparse-memory −11%**. The most quantified continual-learning result.
  Companion essay frames the parametric-vs-external debate: both have failure modes.
- **Long-horizon collapse:** HORIZON benchmark (arXiv:2604.11978, 2026 — *flagged unverified*)
  — subplanning errors + memory limits + forgetting dominate; planning failures propagate.
- **Benchmark integrity crisis:** UC Berkeley RDI showed major agent benchmarks can be
  reward-hacked toward ~100% (rdi.berkeley.edu, Apr 2026 — *Medium*). Read "self-improvement"
  numbers skeptically.

---

## 3. Who is working on it

### Industry labs
- **Meta FAIR** — *Jason Weston*, Ping Yu, Jing Xu, Ilia Kulikov (System-2→System-1
  distillation, self-rewarding models); *Jessy Lin* (sparse-memory continual learning, w/ Berkeley).
- **Google DeepMind** — *Aviral Kumar, Kelvin Xu, Jaehoon Lee* + *Charlie Snell* (compute-optimal
  test-time scaling, arXiv:2408.03314); ReasoningBank team (*Siru Ouyang* et al.). *David Silver*
  & *Richard Sutton* ("Era of Experience" vision).
- **UC Berkeley Sky / Letta** — *Joseph Gonzalez, Ion Stoica*; *Charles Packer, Sarah Wooders,
  Kevin Lin* (MemGPT/Letta, sleep-time compute).
- **DeepSeek** (R1 RL-reasoning), **Alibaba/Qwen** (Qwen3 thinking budgets), **Huawei Noah's
  Ark** (DEER co-author; "Reasoning on a Budget" survey), **NVIDIA/Caltech** (*Anima
  Anandkumar*, Voyager), **Sakana AI** (Darwin Gödel Machine).

### Academic labs
- **Stanford** — *Tatsunori Hashimoto, Percy Liang, Christopher Manning, Christopher Potts,
  Fei-Fei Li* (s1; depth-efficiency); *Joon Sung Park* (Generative Agents).
- **Princeton** — *Mengdi Wang* (self-evolving survey); *Karthik Narasimhan, Shunyu Yao*
  (Reflexion lineage; Narasimhan/Danqi Chen on agents/reasoning).
- **UIUC** — *Heng Ji* (self-evolving survey); *Jiawei Han* (ReasoningBank collaborator).
- **CMU** — *Graham Neubig, Daniel Fried, Zhiruo Wang* (Agent Workflow Memory, web agents,
  self-improving skills); *Sean Welleck, Pranjal Aggarwal* (L1/LCPO).
- **Rice** — *Xia Hu* group (*Stop Overthinking* efficient-reasoning survey).
- **Rutgers AGI Research** — *Yongfeng Zhang, Wujiang Xu, Kai Mei* (A-MEM).
- **Renmin University (RUC GSAI)** — *Xu Chen, Ji-Rong Wen, Wayne Xin Zhao* (agent-memory survey).
- **Shanghai AI Lab** — *Bowen Zhou, Kai Chen* (experience-driven lifelong learning, self-search RL).
- **Tsinghua** — *Maosong Sun* (efficient reasoning); *Gao Huang* LeapLab (ExpeL).
- **UW / AI2** — *Hannaneh Hajishirzi, Luke Zettlemoyer, Pang Wei Koh* (co-authors on s1).
- **EU** — *Zaiqiao Meng* (Glasgow), *Nikos Aletras* (Sheffield), *Zhaochun Ren* (Leiden) —
  second major self-evolving-agents survey (EvoAgentX).
- **UBC/Vector** — *Jeff Clune, Shengran Hu, Cong Lu* (ADAS, Darwin Gödel Machine).

**Field-mapping surveys (author lists = who's active):** 2507.21046 (self-evolving, ASI
framing), 2508.07407 (self-evolving, EU-led), 2507.02076 (Reasoning on a Budget — Huawei +
McGill *Mark Coates*), 2503.16419 (Stop Overthinking — Rice), 2404.13501 & 2512.13564
(agent memory — RUC/Fudan).

---

## 4. Maturity map — done / in-progress / open

| Sub-area | Status | Evidence |
|---|---|---|
| Vendor thinking-budget controls | ✅ **Done / shipped** | Gemini, Claude, OpenAI, Qwen3, DeepSeek in production |
| Budget forcing / test-time scaling | ✅ **Done** | s1 reproducible; flattening understood |
| Confidence-gated early exit | ✅ **Done** | DEER: −31–43% tokens, +acc, training-free |
| LLM routing / cascades | ✅ **Done** | RouteLLM ~95% quality @ ~14% strong calls |
| Distilling *easy* System-2 → System-1 | �️ **Partial** | works for R&R/S2A/BSM; fails for hard CoT |
| Skill libraries / workflow memory | 🟡 **Partial→working** | Voyager, AWM (+51% WebArena), ExpeL |
| Self-editing code agents | 🟡 **In progress, contested** | DGM/SICA big jumps; benchmark-hacking crisis |
| Continual learning w/o forgetting | 🟡 **In progress** | sparse-memory FT promising; not solved at scale |
| Memory drift / error accumulation | 🔴 **Open** | experience-following, SSGM, poisoning |
| Long-horizon agency | 🔴 **Open** | HORIZON: agents still collapse |
| Distilling *hard* multi-step reasoning to one pass | 🔴 **Open** | Meta FAIR's own negative result |
| Per-query difficulty estimation | 🔴 **Open** | routing/early-exit bottleneck |
| Trustworthy long-lived-agent benchmarks | 🔴 **Open** | reward-hacking (Berkeley RDI) |
| Validation/audit of self-evolving agents (regulated) | 🔴 **Wide open** | near-empty niche (§6) |

---

## 5. Possible / current / futuristic

**Demonstrably possible today:** test-time "System-2" reasoning (o1/R1-class) and controllable
fast/slow mixing (System-1.x); in-session tool/skill libraries + episodic retrieval;
trajectory→skill proceduralization; narrow experiential RL in *verifiable* domains
(AlphaProof-style math, games, executable-reward code); metacognitive fast/slow arbitration in
constrained settings (SOFAI; *npj AI* 2025).

**Current frontier (active, partially working, contested):** continual/lifelong learning across
sessions — widely called *the* missing capability (Dwarkesh Patel's "continual learning
bottleneck"; rebuttals by Lambert/Mowshowitz; catastrophic forgetting unsolved at scale,
arXiv:2504.01241); open-ended grounded-reward design; self-evolving agents with persistent memory.

**Speculative (flagged as vision, not demonstrated):** a unified "new kind of mind" with genuine
reflexes, instincts, and durably-accumulating lived experience — the strong **Silver–Sutton
"Era of Experience"** claim (streams, grounded actions/observations, grounded rewards,
non-human planning). Its documented Achilles' heel: grounded-reward learning *re-opens*
specification gaming / reward hacking ("The Era of Experience has an unsolved technical
alignment problem", Alignment Forum, 2025). Also speculative: **LeCun's JEPA/world-models**
path superseding LLMs (AMI Labs, reportedly ~$1B seed 2026 — *secondary press, approximate*);
and using **maladaptive fear/avoidance neuroscience as a deliberate agent-design principle**
(the neuroscience exists — model-free vs model-based RL, Daw/Dolan/Dayan — but a robust AI-design
literature operationalizing fear-avoidance does **not** — treat as aspirational).

**The dual-process analogy itself:** taken seriously as a *design heuristic* (Bengio's
*Consciousness Prior* + "System 2 deep learning"; SOFAI; System-1.x; the 2025 reasoning-LLM
wave), but skeptically as a *literal cognitive claim* — Kahneman-era dual-process theory has
replication problems, and adding CoT tokens lengthens the path without being true "deliberation"
("Reasoning on a Spectrum", arXiv:2502.12470; CACM 2025, DOI 10.1145/3715709).

**Neuroscience design bridges that ARE real:** model-free (habit, dorsolateral striatum) vs
model-based (goal-directed) RL maps cleanly onto System-1/System-2 (Botvinick et al., *Neuron*
2020); the declarative "know-what" vs procedural "know-how" split now structures agent-memory
work; habit consolidation (effortful search → cached skill) is the direct analog of
trajectory→skill proceduralization (K²-Agent; ImplicitMemBench, 2026 — *flagged*).

---

## 6. The governance / regulated-industry gap (the neglected intersection)

**Headline finding:** every mature regime "solves" self-learning AI by *not letting it freely
self-modify*.

- **FDA — Predetermined Change Control Plan (PCCP)**, final guidance Dec 3 2024. Pre-authorize
  *specified, bounded* future changes (Description of Modifications + Modification Protocol +
  Impact Assessment), limited to original intended use. Lineage: 2019 SaMD "locked vs
  continuously-learning" framing → GMLP (2021) → PCCP. Consensus reading: **fully autonomous,
  unbounded continuous learning is not supported.** Jan 2025 draft adds a Total-Product-Life-Cycle
  lifecycle-management framework with postmarket monitoring.
- **EU AI Act (2024/1689)** — *identical logic.* Art. 3 "substantial modification" → Art. 43(3)
  triggers a new conformity assessment; **Art. 43(4) / Recital 128:** changes from continued
  learning are *not* substantial **iff pre-determined by the provider and assessed at initial
  conformity assessment** (documented in Annex IV). Unanticipated drift = substantial
  modification = re-assessment. High-risk obligations (logging, oversight) bite **Aug 2 2026**.
- **Pharma GxP — where "validated state" lives.** GAMP 5 2nd ed. (2022) + the **ISPE GAMP Guide:
  Artificial Intelligence** (Jul 2025, ~290pp). CSV assumes static deterministic software; a
  validated state persists until change-control triggers revalidation. Continuously-learning,
  probabilistic, black-box models break this by changing *between* change events ("dynamic
  systems"; GAMP "Appendix D11" per secondary sources — *exact number unverified*). ALCOA+ data
  integrity + 21 CFR Part 11 audit trails are hard to satisfy for memory-accumulating systems
  whose "record" is a mutating internal state. Practical posture: deploy **frozen/locked models**,
  gate retraining through change control. Emerging idea: "progressive validation."
- **Finance — SR 11-7 / OCC 2011-12** (2011). Three lines of defense, independent validation,
  ongoing monitoring. Held "fully applicable" to ML/GenAI/agents but predates the problem 13+
  years; no binding US text governs self-modifying financial models (proposals exist, e.g.
  Raheja, SSRN).
- **ISO/IEC 42001** (AI management systems, certifiable) + **NIST AI RMF** set *process*
  expectations for ongoing monitoring but give **no testable acceptance criteria for
  continuous-learning drift.**

**The academic-vs-regulatory disconnect.** A real 2025–26 literature now names the problem —
*Agent Drift* + Agent Stability Index (arXiv:2601.04170); *SSGM: Stability and Safety-Governed
Memory* (arXiv:2603.11768 — decouples memory evolution from execution, gates writes); memory
poisoning / "mnemonic sovereignty" (2604.16548, 2512.16962); MIT's *2025 AI Agent Index*
(only 4 of 13 frontier agents disclosed agentic safety evals). But these rarely cite GAMP,
ALCOA+, Part 11, PCCP, or SR 11-7 — and the GxP/CSV practitioner literature rarely cites the
agent-drift research. **The one genuine crossover is *AI Agents Under EU Law* (arXiv:2604.04604,
2026)** — "runtime state must be treated as versioned architecture"; if memory updates and
tool/policy binding aren't "scoped and replayable, drift and variance become indistinguishable."

**Assessment of neglectedness:** *materially underexplored.* Regulators handle it by forbidding
it; the academic answer so far is to *re-impose determinism* (version runtime state, gate memory
writes) — i.e., make the agent *less* self-evolving so it can be audited. **No one has squared
genuinely autonomous behavioral evolution with regulatory traceability.** The widest gap:
agentic systems with persistent learned memory in *any* regulated vertical — there is no
PCCP-equivalent, GAMP appendix, or SR 11-7 supplement for an agent that rewrites its own
behavior from accumulated experience. *(Directly relevant to a GMP-inspection context.)*

---

## 7. Where high-impact funding should go — prioritized fundable bets

Ranked by (impact × neglectedness × tractability). Bottleneck = what actually limits progress.

1. **Governance of learning systems for regulated domains** — *idea/talent-bottlenecked, low
   capital, high neglectedness.* Build the missing bridge: map self-evolving-agent mechanics
   (memory consolidation, online learning, tool/policy drift) onto concrete validation
   requirements — "validated state", ALCOA+/Part 11 audit trails, PCCP Modification Protocols,
   SR 11-7 ongoing validation, EU Art. 43(4) pre-determined-change envelopes. Deliverables: a
   GAMP-compatible "validation framework for memory-accumulating agents", a replayable
   agent-audit-trail standard, drift-detection instrumentation that distinguishes drift from
   variance. **The pharma/GMP angle is the standout — the niche is near-empty (only an EU-law
   paper exists).** Cheap to start, high societal value, defensible.

2. **Continual / lifelong learning without catastrophic forgetting** — *idea-bottlenecked with
   moderate compute.* The consensus "missing capability." Sparse-memory finetuning is the most
   promising lead; the parametric-vs-external-memory tradeoff is unresolved. High impact, very
   crowded interest but not solved.

3. **Trustworthy long-lived-agent evaluation** — *idea-bottlenecked, low capital.* Given the
   reward-hacking crisis (Berkeley RDI) and HORIZON-style collapse, the field lacks credible
   benchmarks for memory/self-improvement over long horizons. Without this, every "self-evolving"
   claim is unfalsifiable. Cheap, foundational, neglected relative to capability work.

4. **Reward / specification design for grounded experiential agents** — *idea-bottlenecked.*
   The unsolved alignment core of the "Era of Experience"; grounded rewards re-open spec gaming.
   High impact, genuinely hard.

5. **Robust System-2 → System-1 distillation of hard reasoning** — *compute- and
   idea-bottlenecked.* Cracking Meta FAIR's negative result (internalizing genuine multi-step
   reasoning) would be transformative for cost/latency but is hard and capital-intensive.

6. **Computational-neuroscience → agent-architecture bridges** — *idea-bottlenecked, low
   capital, high neglectedness.* Principled import of habit consolidation, model-based/model-free
   arbitration, and metacognitive control into agent memory/skill design. Speculative but cheap
   and underexplored.

**Compute/capital-bottlenecked (only with deep pockets):** frontier capability scaling;
AI-for-science compute platforms (DOE Genesis Mission, Nov 2025); world-model bets (LeCun's
AMI Labs). **Idea/talent-bottlenecked (fundable cheaply, higher neglectedness):** bets 1, 3, 6
above — where modest, well-targeted money buys disproportionate societal value.

**Funding landscape context:** NSF AI Institutes (~$100M July-2025 round, >30 institutes); UK
ARIA *Safeguarded AI* (£59M, quantitative safety guarantees — closest existing analog to bet 1);
EU Horizon/GenAI4EU (>€2B 2026–27); Open Philanthropy/Coefficient Giving ($40M technical
AI-safety RFP, 2025); Schmidt Sciences AI2050. The dominant 2025 reframing: the binding
constraint is increasingly *experiment throughput, data quality, and energy* — not raw ideas
or even raw compute (Amplify Partners; Stanford HAI AI Index 2025).

---

## 8. Key source list

*(Confidence: foundational 2023–2025 entries are High and cross-corroborated; `26xx` IDs are
flagged unverified — titles plausible, numbers unconfirmed.)*

**Adaptive compute / distillation:** s1 (2501.19393) · L1/LCPO (2503.04697) · DEER (2504.15895) ·
RouteLLM (2406.18665) · Distilling System 2 into System 1 (2407.06023) · Scaling Test-Time
Compute Optimally (2408.03314) · Sleep-time Compute (2504.13171) · Stop Overthinking (2503.16419) ·
Increasing the Thinking Budget is Not All You Need (2512.19585) · Qwen3 (2505.09388) · DeepSeek-R1
(2501.12948).

**Memory / self-evolution:** Reflexion (2303.11366) · Generative Agents (2304.03442) · Voyager
(2305.16291) · ExpeL (2308.10144) · MemGPT (2310.08560) · Agent Workflow Memory (2409.07429) ·
A-MEM (2502.12110) · Mem0 (2504.19413) · ADAS (2408.08435) · Gödel Agent (2410.04444) · SICA
(2504.15228) · Darwin Gödel Machine (2505.22954) · ReasoningBank (2509.25140) · Sparse Memory
Finetuning (2510.15103) · Experience-Following (2505.16067) · Self-Evolving Agents survey
(2507.21046) · Memory survey (2512.13564) · HORIZON (2604.11978, *unverified*).

**Governance:** FDA PCCP final guidance (Dec 2024, fda.gov/media/180978) · GMLP (2021) · EU AI
Act Art. 3/43/Recital 128 (artificialintelligenceact.eu) · ISPE GAMP AI Guide (Jul 2025) ·
SR 11-7 (2011) · ISO/IEC 42001 · NIST AI RMF · Agent Drift (2601.04170, *unverified*) · SSGM
(2603.11768, *unverified*) · AI Agents Under EU Law (2604.04604, *unverified*) · MIT 2025 AI
Agent Index (2602.17753, *unverified*).

**Vision / neuroscience / funding:** Bengio Consciousness Prior (1709.08568) · SOFAI / *npj AI*
2025 (s44387-025-00027-5) · System-1.x (2407.14414) · Reasoning on a Spectrum (2502.12470) ·
Silver & Sutton "Era of Experience" (2025) · The Era of Experience alignment problem (Alignment
Forum 2025) · LeCun "Path Towards Autonomous Machine Intelligence" (2022) · Botvinick et al.
*Neuron* (2020) · Lifelong Learning of LLM Agents roadmap (2501.07278) · DOE Genesis Mission
(Nov 2025) · ARIA Safeguarded AI · Stanford HAI AI Index 2025.

---

*Prepared June 2026. Re-verify any `26xx` arXiv ID and vendor-self-reported benchmark figure
against primary full text before external publication.*

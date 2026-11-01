# Election Commission of India: ECINet Definitive Forensic Dissection

## Operational Intelligence Dossier & Technical Evidence Baseline
**Target Portal:** `https://ecinet.eci.gov.in/`  
**Production Build Date:** `1792138790947` (`main.6faf5084.js`)  
**Evidence Standard:** Confirmed via static AST extraction, cryptographic verification, exact byte offsets, and client routing decompilation.

---

## 1. Cryptographic Architecture: The Dual-Implementation Divergence
### A. Compliant Hybrid Envelope Encryption in Production (Module 5606 & Module 69303)
- **Exact File:** `ecinet_main_unescaped.js` (Module `5606` at **Byte Offset: 237,195**, integrated via Module `69303` at **Byte Offset: 1,172,468**).
- **Asymmetric Key:** 2048-bit RSA public key embedded directly: `s = "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEArb7++BxL/YN8OIln+6FL9Gnw5DNmQ/VFZXss+J+TuQyJc891JbqbijxYQNEin2c2u+CnpXpoGQ/1gUSzDMJeNS3sNSlIUykp2dt7xIm/cmV4sZ/c769vCxVRosMfRaZJnBAah+m1X26lEhnOo0wpAB9Txr8RIyBe6h7PiQWykeJeh6UacOBBX28kgkq7+vJhW8HgB38lt32XRocznRYwS9LqR7ZweFmQhTr1+EGrqiEKCOCxMYgHR2SQckb96hZ9kWzfzeun4bUO5oXKJciLkiS1IgKieADEvYLgu129ZIpn1H+8H+8ikNNVETqEDDMtqcQcQmWppJvcWHaXAs+f8QIDAQAB"`
- **Key Freshness:** Ephemeral 256-bit AES key per request via `window.crypto.getRandomValues(new Uint8Array(32))`.
- **Nonce Freshness:** Ephemeral 12-byte GCM IV per request via `window.crypto.getRandomValues(new Uint8Array(12))`.
- **Authenticated Encryption:** `AES-GCM` authenticated payload encryption with `RSA-OAEP` (SHA-256) key encapsulation.

### B. Broken Cryptographic Subsystems (Modules 28636 & 37050)
1. **CWE-327 (Electronic Codebook - ECB Mode) + CWE-321 (Hardcoded Symmetric Key):**
   - **Exact File:** `ecinet_chunk_4264.js` (Module `28636`, Line 1).
   - **Key Origin:** `ecinet_main_unescaped.js` (Module `49981`, **Byte Offset: 723,350**, Constant `Ct` -> `Lq`: `4WS8851W824PRA45`).
   - **Usage:** AES-128-ECB PKCS7 encryption for `/eci-backend/public/api/get-index-card-details?cat_id=FR%2FE3iiuGMwW5bXp1g0BWA%3D%3D`.
2. **CWE-321 Static Fallback IV Subsystem:**
   - **Exact File:** `ecinet_chunk_5481.js` (Module `37050`, **Byte Offset: 4,050**).
   - **Static Secrets:** Static key `9567b98056e9250c`, static fallback IV `REACT_APP_CKP_IV` (`38c2323e42994e41`).

---

## 2. Statutory Digital Custody: Rules 92, 93, 94 CER 1961 & Defensive Merkle Architecture
### A. Statutory Text & Precedent
- **Rule 92 CER 1961 (Custody of Election Papers):** The District Election Officer (DEO) is the sole lawful statutory custodian. Delegating storage to unindexed cloud buckets without verifiable custody breaks the chain of custody.
- **Rule 93(1)(dd) CER 1961 (Production & Inspection of Election Papers):** Packet of Form 17C Part I & Part II shall not be opened except under the order of a competent court. Bypassing court seals via web portal presigned URLs is ultra vires.
- **Section 94 RPA 1951 (Secrecy of Voting Not to be Infringed):** Protects voter secrecy. Correlating unindexed voter timestamps with EVM polling metrics violates Section 94.
- **BSA 2023 Section 63 / IEA Section 65B (*Arjun Panditrao Khotkar v. Kailash Kushanrao Gorantyal* [2020] 7 SCC 1):** Electronic evidence from mutable, non-WORM object storage lacks non-repudiation and cannot be certified by the lawful custodian.

### B. Defensive RFC 6962-Style Merkle Transparency Architecture
- **Source Sealing:** Polling Station generation with DSC / PAdES hardware cryptographic signatures.
- **Append-Only Merkle Sequencer:** RFC 6962 transparency log with SHA-256 leaf digests.
- **Verifiable Non-Repudiation:** Public Signed Tree Heads (STH) with gossip witnesses and S3 Object Lock (WORM).

---

## 3. Severed Statutory Routing Analysis
- **Catalog vs Router Audit:** Out of **102 dashboard items** declared in `DASHBOARD_TITLES_MAPPED_TO_IDS` (Byte Offset 487,732):
  - **65 items are bound** to executable React Router component paths.
  - **37 statutory reports are completely severed** (unrouted dead ends / 404s).
- **Key Severed Reports:**
  - ID `45`: `Form 17C - Part I (Account of Votes Recorded)` — Unrouted.
  - ID `44`: `Form 17C - Part II (Result of Counting)` — Unrouted.
  - ID `59`: `Mock Poll Certificate Dashboard` — Unrouted.
  - ID `38`: `EVMs Replacement Dashboard` — Unrouted.
  - ID `46`: `Form 22 (Certificate of Election)` — Unrouted.
  - ID `68`: `Presiding Officer Diary` — Unrouted.
- **100% Omission of Form 17A:** Form 17A (Register of Voters) is entirely omitted from both the catalog and router.

---

## 4. Finding #27: The 2003 Ancestral Lineage & Last SIR Verification Engine
- **Exact File:** `ecinet_chunk_8556.js`
- **Exact Byte Offset:** `36,442`
- **Target Endpoint:** `POST https://gateway-s2-blo.eci.gov.in/api/v1/elastic-sir/get-eroll-data-2003`
- **Configuration:** `{ withCredentials: false }` (Bypasses session authentication/CORS checks).
- **Genealogical Branching:** Evaluates `categoryType === "self"` vs `categoryType === "progeny"` to retrieve ancestral legacy roll records dating back to 2003.

---

## 5. Finding #28: Unindexed Object Storage Architecture with Presigned URLs
- **Exact Files & Offsets:**
  - `ecinet_main_unescaped.js`: Offsets `1,260,136` to `1,260,656`.
  - `ecinet_chunk_8556.js`: Offsets `18,401`, `20,288`, `32,867`, and `47,034`.
- **Target Endpoints:**
  - `OBJECTSTORE_GET_URL`: `api/v1/objectstore/get`
  - `OBJECTSTORE_UPLOAD_URL`: `api/v1/objectstore/upload`
  - `OBJECT_STORE_GET_PRESIGNED_BASE_URL`: `api/v1/objectstore/getPresignedUrl`
- **Storage Pattern:** Flat query parameter retrieval: `?bucketName=objectstorage&fileName=<ephemeral_string>`.

---

## 6. Finding #29: The Undisclosed Demographic & Genealogical Profiling Engine
- **Exact File:** `ecinet_chunk_9226.js`
- **Exact Byte Offsets:** `28,789` & `29,453`
- **Hardcoded State Baseline:** `children: ["Electors with Discrepancies - ", ("West Bengal" == Tl && bo ? 9449132 : mo?.anomalyCount)]` (Offset 28,789)
- **The 5 Genealogical Anomaly Variables (Offset 29,453):**
  1. `progLimitExceed`: `"Progeny >= 6"`
  2. `parentNameMismatch`: `"Father Name Mismatch"`
  3. `parentAgeLt15`: `"Parent Age Difference <15"`
  4. `parentAgeGt50`: `"Parent Age difference >50"`
  5. `gparentAgeLt40`: `"Grandparent Age difference <40"`
- **Statutory & Constitutional Ground:**
  - *Lack of Statutory Authority:* Sections 16 & 19 RPA 1950 do not authorize family size or biological age differentials as voter eligibility criteria.
  - *Outside the ADR v. ECI (May 2026) Record:* The Supreme Court upheld the ECI's general SIR authority based on the public 11/12-document SOP; these internal algorithmic filters were never disclosed to the Court.
  - *Manifest Arbitrariness (Article 14, Shayara Bano):* Executive classification on family size lacks a rational nexus to residency or citizenship.
  - *Disparate Impact & Indirect Discrimination (Articles 14 & 15(1), Lt Col Nitisha [2021] & Navtej Johar [2018]):* Data from successive National Family Health Surveys (NFHS-4 and NFHS-5) establishes that higher parity rates (>=6 children) and multi-generational joint families correlate directly with specific socio-economic, rural, and minority demographic cohorts. Applying facially neutral algorithmic filters (progLimitExceed) disproportionately subjects these cohorts to heightened scrutiny and verification burdens without statutory authority.
  - *Subversion of the Single General Electoral Roll (Article 325):* Article 325 mandates a single general electoral roll and forbids exclusionary classification. Hardcoding a 9,449,132 baseline for West Bengal and setting fertility triggers creates a de facto bifurcated roll—an adverse administrative holding pen.

---

### Finding #30: The Automated Form 7 Electoral Deletion Pipeline
- **Exact File:** `ecinet_main_unescaped.js`
- **Exact Byte Offsets:** `1,267,634` & `347,882`
- **Automated Deletion Endpoints:**
  - `UPDATE_IN_EROLL`: `"api/v1/eroll-management/erollUpdateForAutoForm7"`
  - `AUTOFORM7_DATA`: `"api/v1/formProcessingService/getAutoForm7Popup"`
  - `APPELLIATE_INFO_URL`: `"/api/v1/ngsp-manageappeal/fetchAppealOfficer?District="`
  - `UPDATE_APPELLIATE_OFFICER`: `"/api/v1/ngsp-manageappeal/manageAppealOfficer"`
- **Redux PopUp State Machine:**
  - `name: "popUp", initialState: { dashboardPendencyPopup: !0, instructionPopUp: !1, autoForm7PopUp: !1, callingInstructionPopUp: !1 }, reducers: { setAutoForm7PopUp: ... }`
- **Statutory & Constitutional Ground:**
  - *Circumvention of Rule 13(2) & Rule 21A (RER 1960):* Form 7 is strictly an individual statutory objection requiring an identifiable human applicant. Automated programmatic generation (`AutoForm7`) bypasses individual standing and mandatory individualized notice/hearing.
  - *Violation of Natural Justice in ADR v. ECI (May 2026):* Supreme Court explicitly held that roll revisions must comply with Rule 21A audi alteram partem safeguards; automating deletion queues via backend batch triggers circumvents these statutory protections.
  - *Evidentiary Inadmissibility (BSA 2023 §63 / IEA §65B):* Algorithmic deletions without human complainant affidavits cannot be certified as lawful statutory objections under Arjun Panditrao Khotkar (2020).

---

### Finding #31: The Extra-Statutory "Judicial Officer" & "Appellate Tribunal" Shadow Machinery
- **Exact Files & Offsets:** `ecinet_chunk_9683.js` (Offsets 3,695, 3,833, 3,908, 9,198) & `ecinet_chunk_164.js` (Offset 1,200).
- **Target Routes:**
  - `/home/sir/sir-phase2/individuals-under-adjudication-dashboard`
  - `/home/sir/sir-phase2/appellate-tribunal-appeal-dashboard`
- **Target APIs & Exports:**
  - `POST api/v1/druid/noticeJudgeHearing` & `POST api/v1/druid/joUserDetails`
  - `POST api/v1/druid/appeal`
  - Export PDF: `${Q}_Electors_Under_Adjudication.pdf` & `${$}_JO_Appeal_Report.pdf`
- **The Adjudication & Deletion Execution Pipeline:**
  - Judicial Officer designation: `joFullName`, `actionTakenByJudge`, `approvedByJo`, `rejectedByJo`.
  - Table metrics: `foundEligible`, `foundNotEligible`, `judgeActionTaken`.
  - Direct pipeline to roll purge: `esignedEligible` maps to `"For Supplementary list"` (Voters kept/added); `esignedIneligible` maps directly to **`"For Deleted list"`** (Voters purged via `erollUpdateForAutoForm7`).
- **Proof of Direct Violation of Supreme Court Mandate in ADR v. ECI (2026 INSC 564):**
  - The Supreme Court on May 27, 2026 ordered that electors doubted on citizenship grounds must be referred within four weeks specifically to the Competent Authority under the Citizenship Act, 1955 (MHA).
  - **Exhaustive code audit across all 161 Webpack chunk mappings proves ZERO references to MHA, Ministry of Home Affairs, Competent Authority, or external statutory referral.**
  - The system functions as a closed-loop internal citizenship tribunal, usurping both the ERO's statutory discretion (violating *Purtabpore*) and Parliament's exclusive power to constitute tribunals under Entry 72/95 List I (violating *Madras Bar Association*).

---

## 7. Microservice Inventory Summary (251 Endpoints / 36 Services)
- `user-management`: 69 endpoints (role mapping, disable officer, Keycloak assign)
- `druid`: 19 endpoints + `analytics`: 8 endpoints (Druid roll query, gender ratio, anomaly metrics)
- `vendor`: 14 endpoints (agency credentials, vendor assignment, SLA)
- `political-party-user-management`: 12 endpoints (party admin, BLA approval, status toggle)
- `enumerationFormData`: 12 endpoints (H2H survey, offline enumeration, verification)
- `printing-publish`: 6 endpoints (AC roll publishing, published PDF download)
- `eci-sir`: 5 endpoints (`getSsrDetails`, `getNotSubmittedEpics`, `getUncollectableEnumDetails`)
- `candidate-user-management`: 5 endpoints (candidate OTP, password reset, user creation)
- `bloapp` cluster: 11 endpoints (`bloapp`, `bloapp-h2h`, `bloapp-lite`, `blocard`)
- `external`: Turnout stats redirected to third-party proprietary TCS cloud (`/tcs/v1/get-voterturnout`).

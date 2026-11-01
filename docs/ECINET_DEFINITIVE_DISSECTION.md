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
   - **Usage:** AES-128-ECB PKCS7 encryption for `/eci-backend/public/api/get-index-card-details?cat_id=FR%2FE3iiuGM9sewDDzjJyCQ%3D%3D&page=`. Identical plaintext blocks produce identical ciphertext blocks, leaking structural frequency.
2. **CWE-329 (Static Nonce/IV Reuse in AES-GCM) + CWE-321 (Hardcoded Symmetric Key):**
   - **Exact File:** `ecinet_chunk_3209.js` (Module `37050`, Line 1).
   - **Key/IV Origin:** `ecinet_main_unescaped.js` (Module `49981`, **Byte Offset: 723,350**, Key `wt = "9567b98056e9250c"`, Static IV `Ot = "558fadb2c64c25ec"`).
   - **Usage:** Static IV reuse across all client sessions destroys Galois/Counter mode authenticity guarantees and enables GHASH authentication key recovery.

---

## 2. Statutory Digital Custody: Rules 92, 93, 94 CER 1961 & Defensive Merkle Architecture
### A. Statutory Text & Precedent
- **Rule 92 (Conduct of Elections Rules, 1961):** Primary custody provision mandating that election packets remain in safe custody of the District Election Officer.
- **Rule 93 (Production & Inspection):** Governs inspection once in custody. Form 17A registers fall under Rule 93(1)(dd), strictly requiring a competent court order (*Ram Sewak Yadav v. Hussain Kamil Kidwai*, *Hari Ram v. Hira Singh*).
- **Rule 94 (Disposal):** Sets mandatory retention periods.
- **The Technical Audit Fact:** Under Section 100(1)(d) RPA 1951, the legally defensible finding is that **in the absence of an append-only cryptographic hash log, the custody integrity of digital records stored in mutable flat object storage cannot be independently verified**.

### B. Defensive RFC 6962-Style Merkle Transparency Architecture
1. **Content-Addressing at Submission:** Every Form 17A/17C record is SHA-256 hashed immediately upon finalization.
2. **Append-Only Merkle Log (RFC 6962):** Each hash becomes a leaf in an append-only tree.
3. **Multi-Party Signed Tree Heads (STHs):** Periodic STHs published to independent, mutually distrusting parties (party BLAs, court registry, press pool).
4. **Co-Signing at Creation:** Presiding officer and polling agents sign the leaf hash prior to insertion.

---

## 3. Severed Statutory Routing Analysis
- **UI Data Model Catalog:** 102 items in `DASHBOARD_TITLES_MAPPED_TO_IDS` (Module `z1`, offset 487,732).
- **Executable Router:** 109 bound routes (`createBrowserRouter`, offset 1,209,270).
- **Severed / Unrouted Items:** **37 out of 102 reports** have no bound component and fall into wildcard 404 handlers.
  - Critical Severed Reports: Form 17C (`[44]`), Form 17C Part 1 (`[45]`), Mock Poll Certificate (`[59]`), Mockpoll (`[60]`), EVMs Replacement (`[38]`), EVM Details (`[37]`), Form 22 (`[46]`), Form 22/24 Ack (`[47]`), Form 24 (`[48]`), Poll Day Report Annexure 28 (`[67]`), Feedback Report Annexure L (`[41]`), BLO Register (`[9]`), Manpower (`[57]`), Observer (`[62]`).
  - Total Absence: **Form 17A (Register of Voters)** is absent from both the catalog and router.

---

## 4. Finding #27: The 2003 Ancestral Lineage & Last SIR Verification Engine
- **Exact File:** `ecinet_chunk_8556.js`
- **Exact Byte Offset:** `36,442`
- **Endpoint:** `POST https://gateway-s2-blo.eci.gov.in/api/v1/elastic-sir/get-eroll-data-2003`
- **Configuration:** `{ withCredentials: false }` (unauthenticated cross-origin request)
- **Branching Logic:**
  - `categoryType === "self"` -> `Tl(V.oldStateCd, V.oldAcNo, V.oldPartNo, V.oldPslNo, "Blo")`
  - `categoryType === "progeny"` -> `Tl(V.relationOldStateCd, V.relationOldAcNo, V.relationOldPartNo, V.relationPlsPslNo, "Blo")`
  - ERO Administrative Audit: `Tl(V.lastSirState, V.lastSirAc, V.lastSirPart, V.lastSirSerialNo, "Ero")`

---

## 5. Finding #28: Unindexed Object Storage Architecture with Presigned URLs
- **Exact File:** `ecinet_main_unescaped.js`
- **Exact Byte Offsets:** `1,260,136` through `1,260,656` (Module `yl`)
- **Integration Offsets in `ecinet_chunk_8556.js`:** `18,401`, `20,288`, `32,867`, and `47,034`
- **Verbatim Endpoints:**
  ```javascript
  OBJECTSTORE_GET_URL: "api/v1/document/getFile?bucketName=objectstorage&fileName=",
  OBJECT_STORE_GET_PRESIGNED_BASE_URL: `${o.nH}/getPresignedFile?bucketName=objectstorage&fileName=`,
  OBJECT_STORE_DOWNLOAD_PRESIGNED_BASE_URL: `${o.nH}/downloadPresignedFile?bucketName=objectstorage&fileName=`,
  OBJECT_STORE_GET_FILE_BASE_URL: `${o.nH}/getFile?bucketName=objectstorage&fileName=`,
  OBJECTSTORE_UPLOAD_URL: "api/v1/document/uploadFile",
  OBJECTSTORE_DOWNLOAD_URL: "api/v1/document/downloadFile?bucketName=objectstorage&fileName=",
  OBJECTSTORE_DELETE_URL: "api/v1/document/deleteFile?bucketName=objectstorage&fileName="
  ```
- **Extracted Document Types Resolved via Presigned URLs:**
  `ERO/AERO-Extract-of-Last-SIR-`, `Citizen-Extract-of-Last-SIR-`, `BLO-Extract-of-Last-SIR-`, `Citizen-Document-1-Front/Back` through `Citizen-Document-6-Front/Back`, `Supporting-Document-Front/Back`.

---

## 6. Microservice Inventory Summary (251 Endpoints / 36 Services)
- `user-management`: 69 endpoints (role mapping, disable officer, Keycloak assign)
- `druid` & analytics: 28 endpoints (logical discrepancies, BLA pendency, enum tracking)
- `vendor`: 14 endpoints (vendor onboarding, printing export, disable vendor)
- `political-party-user-management`: 12 endpoints (`createBlaFirst`, disable party, BLA2 lookup)
- `enumerationFormData`: 12 endpoints (H2H survey, offline enumeration, verification)
- `printing-publish`: 6 endpoints (AC roll publishing, published PDF download)
- `eci-sir`: 5 endpoints (`getSsrDetails`, `getNotSubmittedEpics`, `getUncollectableEnumDetails`)
- `candidate-user-management`: 5 endpoints (candidate OTP, password reset, user creation)
- `bloapp` cluster: 11 endpoints (`bloapp`, `bloapp-h2h`, `bloapp-lite`, `blocard`)
- `external`: Turnout stats redirected to third-party proprietary TCS cloud (`/tcs/v1/get-voterturnout`).

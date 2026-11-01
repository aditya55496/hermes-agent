# Election Commission of India: ECINet Definitive Forensic Dissection

## Operational Intelligence Dossier & Technical Evidence Baseline
**Target Portal:** `https://ecinet.eci.gov.in/`  
**Production Build Date:** `1792138790947` (`main.6faf5084.js`)  
**Evidence Standard:** Confirmed via static AST extraction, cryptographic verification, and client routing decompilation.

---

## 1. Cryptographic Architecture: Payload Encryption & Offline Parsing
### A. Static Implementation Failure Modes
1. **CWE-327 (Electronic Codebook - ECB Mode) + CWE-321 (Hardcoded Symmetric Key):**
   - **Key:** `4WS8851W824PRA45` (Module `49981` constant `Ct`, exported as `Lq`).
   - **Mode:** AES-128-ECB with PKCS7 padding (Module `28636` in `ecinet_chunk_4264.js`).
   - **Usage:** Deterministic query encryption for `/eci-backend/public/api/get-index-card-details?cat_id=FR%2FE3iiuGM9sewDDzjJyCQ%3D%3D&page=`. Identical plaintext pages yield identical ciphertexts.
2. **CWE-329 (Static Nonce/IV Reuse in AES-GCM) + CWE-321 (Hardcoded Symmetric Key):**
   - **Key:** `wt = "9567b98056e9250c"` (Module `49981`, exported as `Tt`).
   - **IV:** `Ot = "558fadb2c64c25ec"` (Module `49981`, exported as `te`).
   - **Mode:** AES-GCM with 128-bit authentication tag (Module `37050` in `ecinet_chunk_3209.js`).
   - **Usage:** Reusing static IV across all sessions breaks AES-GCM authenticity guarantees and enables GHASH key recovery.

### B. Pure-Python Offline Diagnostic Tool
```python
import base64
import json
from urllib.parse import unquote
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.primitives import padding
from cryptography.hazmat.backends import default_backend

ECB_STATIC_KEY = b"4WS8851W824PRA45"
GCM_STATIC_KEY = b"9567b98056e9250c"
GCM_STATIC_IV  = b"558fadb2c64c25ec"

def parse_offline_ecb_payload(ciphertext_b64: str, static_key: bytes = ECB_STATIC_KEY) -> dict:
    try:
        raw_ciphertext = base64.b64decode(unquote(ciphertext_b64))
        cipher = Cipher(algorithms.AES(static_key), modes.ECB(), backend=default_backend())
        padded_plaintext = cipher.decryptor().update(raw_ciphertext) + cipher.decryptor().finalize()
        unpadder = padding.PKCS7(128).unpadder()
        plaintext = unpadder.update(padded_plaintext) + unpadder.finalize()
        return json.loads(plaintext.decode('utf-8'))
    except Exception as e:
        return {"status": "error", "message": f"ECB Decryption failed: {str(e)}"}

def parse_offline_gcm_envelope(encrypted_payload_b64: str, iv_b64: str, key_bytes: bytes = GCM_STATIC_KEY, tag_length: int = 16) -> dict:
    try:
        raw_payload = base64.b64decode(unquote(encrypted_payload_b64))
        iv = base64.b64decode(unquote(iv_b64))
        ciphertext = raw_payload[:-tag_length]
        tag = raw_payload[-tag_length:]
        cipher = Cipher(algorithms.AES(key_bytes), modes.GCM(iv, tag), backend=default_backend())
        plaintext = cipher.decryptor().update(ciphertext) + cipher.decryptor().finalize()
        return json.loads(plaintext.decode('utf-8'))
    except Exception as e:
        return {"status": "error", "message": f"GCM Decryption failed: {str(e)}"}
```

---

## 2. Statutory Entity-Relationship Model (Conduct of Elections Rules, 1961)
Governed by Rule 49L (Form 17A Register of Voters), Rule 49S (Form 17C Part I Account of Votes), and Rule 56C (Form 17C Part II Counting Result).

```
       +-----------------------+              +---------------------------+
       |   POLLING_STATION     |              |       ELECTOR_RECORD      |
       +-----------------------+              +---------------------------+
       | PK  station_uid       |              | PK  epic_number           |
       |     ac_number         |              |     elector_name          |
       |     part_number       |              |     part_serial_number    |
       +-----------+-----------+              +-------------+-------------+
                   | 1                                      | 1
                   |                                        |
                   | 1..*                                   | 1..*
       +-----------v-----------+              +-------------v-------------+
       |   FORM_17A_REGISTER   |              |  FORM_17A_VOTER_ENTRY     |
       +-----------------------+              +---------------------------+
       | PK  register_id       | 1        1..*| PK  entry_id              |
       | FK  station_uid       +------------->| FK  register_id           |
       |     date_of_poll      |              |     sl_no_in_register     |
       +-----------------------+              |     sl_no_in_electoral_roll|
                                              |     signature_thumb_flag  |
                                              +---------------------------+
                   | 1
                   |
                   | 1
       +-----------v---------------------+
       |    FORM_17C_PART_I_ACCOUNT      |
       +---------------------------------+
       | PK  account_id                  |
       | FK  station_uid                 |
       |     cu_serial_number            |
       |     bu_serial_number            |
       |     vvpat_serial_number         |
       |     total_electors_assigned     |
       |     total_voters_as_per_17A     |
       |     voters_not_allowed_to_vote  |
       |     votes_not_recorded (49M)    |
       |     test_votes_recorded (49MA)  |
       |     total_votes_in_evm          |
       |     discrepancy_17A_vs_evm      |
       |     presiding_officer_sign_dttm |
       +-----------------+---------------+
                         | 1
                         | 1
       +-----------------v---------------+
       |    FORM_17C_PART_II_COUNTING    |
       +---------------------------------+
       | PK  counting_result_id          |
       | FK  account_id                  |
       |     candidate_votes_json        |
       |     total_valid_votes_counted   |
       |     discrepancy_part1_vs_part2  |
       |     returning_officer_sign_dttm |
       +---------------------------------+
```
**Observed Severance:**
- Form 17C / 17A relational schema is completely uninstantiated in the client database models.
- The React router completely omits routes for Form 17C (IDs 44 & 45).
- Form 17A (Register of Voters) is absent from the entire application catalog and routing table.
- Polling station data is shunted to unindexed object storage (`OBJECTSTORE_UPLOAD_URL`).

---

## 3. Severed Statutory Routing Analysis
- **UI Data Model Catalog:** 102 items in `DASHBOARD_TITLES_MAPPED_TO_IDS` (Module `z1`, offset 487,732).
- **Executable Router:** 109 bound routes (`createBrowserRouter`, offset 1,209,270).
- **Severed / Unrouted Items:** **37 out of 102 reports** have no bound component and fall into wildcard 404 handlers.
  - Critical Severed Reports: Form 17C (`[44]`), Form 17C Part 1 (`[45]`), Mock Poll Certificate (`[59]`), Mockpoll (`[60]`), EVMs Replacement (`[38]`), EVM Details (`[37]`), Form 22 (`[46]`), Form 22/24 Ack (`[47]`), Form 24 (`[48]`), Poll Day Report Annexure 28 (`[67]`), Feedback Report Annexure L (`[41]`), BLO Register (`[9]`), Manpower (`[57]`), Observer (`[62]`).

---

## 4. Evidentiary Constitutional Violation Matrix
| # | Technical Artifact | Operating Mechanism | Statutory Breach | Constitutional Articles Violated |
|---|--------------------|---------------------|------------------|----------------------------------|
| 1 | `ctzver` Lineage Logic (Module 53087) | Birth cutoffs (CAT-1 to CAT-4); demands ancestral rolls & parental voter records | Citizenship Act 1955 (§3); Registration of Electors Rules 1960 (Rule 13, Form 6) | **Articles 14, 325, 326:** Ultra vires citizenship proof; breaches universal adult suffrage |
| 2 | `erollUpdateForAutoForm7` / `bulkDeleteAutoForm7Requests` (Module 49981) | Programmatic automated Form 7 voter deletion without physical signed complaints | RPA 1950 (§22, §23); Registration of Electors Rules 1960 (Rules 19, 20) | **Articles 14, 21, 326:** Violates natural justice (*audi alteram partem*); disenfranchisement without hearing |
| 3 | Cleartext Identity Scans (`getForm6DetailsByReferenceNo`) | Unmasked Aadhaar numbers and raw identity scans served over broken client crypto | IT Act 2000 (§43A); Aadhaar Act 2016 (§29); DPDP Act 2023 | **Article 21:** Infringes fundamental right to privacy (*Puttaswamy v. UOI*) |
| 4 | `MARK_POLITICAL_PARTY_DISABLE` (Module 49981) | Unilateral centralized software switch deactivating registered political party profiles & BLAs | RPA 1951 (§29A); Conduct of Elections Rules 1961 (Rule 12) | **Articles 14, 19(1)(c), 324:** Destroys democratic level playing field & statutory audit |
| 5 | `/searchInSIR/S2UA4DPDF-JK4QWODSE` & `bh_2003_eroll` | Unrouted backdoors isolating queries under non-public legacy subsets | Registration of Electors Rules 1960 (Rule 22) | **Articles 14, 325:** Violates single general electoral roll mandate |

---

## 5. Microservice Inventory Summary (251 Endpoints / 36 Services)
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

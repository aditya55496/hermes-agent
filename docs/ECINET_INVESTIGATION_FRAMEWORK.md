# ECINet Continuous Forensic Investigation Framework

## 1. Executive Mission
This document establishes the operational intelligence and baseline state for autonomous agents monitoring and auditing the Election Commission of India (ECINet) unified digital architecture.

Agents running in this environment operate as unattended, 24/7 cloud watchdogs to detect:
1. Production bundle build rotations and hash changes.
2. Silent additions, deletions, or modifications to statutory report routes (Forms 17C, 17A, 6, 7, 8).
3. Secret tokens, backdoor routes, or undocumented internal API paths.

---

## 2. Baseline State & Signatures (Audited: November 2026)
- **Primary Portal URL:** `https://ecinet.eci.gov.in/`
- **Active Production Main Bundle:** `https://ecinet.eci.gov.in/static/js/main.6faf5084.js`
- **Active Production Build Date:** `1792138790947` (from `/meta.json`)
- **Key Cluster Endpoints:**
  - `REACT_APP_BASE_URL`: `https://gateway-officials.eci.gov.in/`
  - `REACT_APP_ERONET_BASE_URL`: `https://officials.eci.gov.in/`
  - `REACT_APP_VSP_URL`: `https://voters.eci.gov.in/`
  - `REACT_APP_ELECTORAL_SEARCH_URL`: `https://electoralsearch.eci.gov.in/uesfmempmlkypo`
  - `REACT_APP_ELASTIC_S2_BLO_BASE_URL`: `https://gateway-s2-blo.eci.gov.in/`

---

## 3. High-Priority Monitored Anomalies (The 26 Findings Baseline)
1. **Citizenship Verification Engine (`ctzver`):** Demands parents' voter cards and pre-1987 ancestral records.
2. **Form 6 Mass Applicant Data & Document Exposure:** Exposes unmasked 12-digit Aadhaar, phone, and uploaded identity scans.
3. **Automated Deletion Pipeline (`erollUpdateForAutoForm7`):** Auto-generates voter deletion forms.
4. **Demographic Profiling ("Progeny >= 6" & WB 9.45M Override):** Flags families with 6+ children.
5. **Digital Adjudication & Judge Swapping:** Software-based reassignment of statutory appeal officers.
6. **Potemkin Village Dummy Monitoring Screens:** Hardcoded placeholder counts for EVM, CAPF, and polling stations.
7. **Cleartext Aadhaar Retrieval (`get-aadhar/internal/`):** Internal API returning raw unmasked Aadhaar.
8. **VIP Gold Voter Classification Badges:** Two-tier classification system inside electoral registry.
9. **Administrative Disabling of Political Parties & BLAs (`markDisable`):** Single API switch to revoke party/agent access.
10. **Biometric Facial Recognition Engine:** Automatic notice generation on photo blurring/similarity.
11. **Secret SIR Backdoor Path & Token:** `/searchInSIR/S2UA4DPDF-JK4QWODSE`.
12. **Unlisted Electoral Search Subpath:** `/uesfmempmlkypo`.
13. **Legacy Baseline Query Route:** `/bh_2003_eroll`.
14. **Ghost Oversight System:** 65 of 102 statutory reports unrouted; Form 17A completely absent.

---

## 4. Autonomous Watchdog Directives
1. **Poll Baseline Integrity:** Query `https://ecinet.eci.gov.in/meta.json` every cycle.
2. **Bundle Diffing:** If `buildDate != 1792138790947`, immediately curl the new `main.*.js`, extract Webpack chunk mappings, and diff against the audited hash table.
3. **Statutory Report Audit:** Check if Form 17A (`reportId` or route `/form17A`) is ever instantiated or if Form 17C (IDs 44/45) routing is restored to public view.
4. **Log & Commit:** Store all audit logs under `telemetry/` with timestamps and severity ratings.

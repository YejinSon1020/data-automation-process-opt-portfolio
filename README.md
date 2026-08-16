# data-automation-process-opt-portfolio
Showcasing data-driven process optimization, JS/Low-code workflow automation, and technical project management case studies.

# 🚀 Technical Operations & Process Automation Portfolio

> **Summary:** Data-Driven Project Analyst & Technical Specialist
> 
> Leveraging **Data Analytics (SQL, Multi-DB Integration)**, **Workflow Logic & AI Automation (JavaScript, Low-Code)**, and **Systemic Process Optimization** to streamline global operational workflows.

---

## 🛠 Technical Skill Set

* **Data Analytics & Engineering:** Multi-DB Integration, SQL (Complex Joins, Aggregations), Business Logic-Driven Data Categorization, Python, Tableau, Metabase
* **Workflow Automation & Logic:** JavaScript (ES6+), Low-Code Guidance Tools, AI Natural Language Intent Extraction & Automation Flows, REST API Integration
* **Process Optimization & System Mapping:** Decision-Tree Mapping, Business Process Modeling (BPMN), UAT (User Acceptance Testing) Leadership
* **Project & Stakeholder Management:** Cross-Functional Alignment, Operational Bottleneck Identification, Performance Metrics Tracking

---

## 📂 Key Achievements & Case Studies

### 1. Workflow Guidance & AI-Driven Email Automation
> **Objective:** Streamline customer support and partner inquiry handling through automated decision trees and AI intent recognition.

* **Key Achievements:**
  * Developed interactive agent guidance flows that dynamically provide correct step-by-step resolution procedures, suggested customer compensation, and script recommendations based on selected case scenarios.
  * Engineered end-to-end automation flows integrated with AI natural language models that parse incoming emails to extract Main/Sub Intents, map them to corresponding operational scenarios, and automatically trigger tailored response emails.
  * Led User Acceptance Testing (UAT) across global test teams to ensure smooth system deployment and operational accuracy.

---

### 2. Multi-DB Data Integration & Multi-Dimensional Analytics
> **Objective:** Unify fragmented operational databases to establish standardized customer touchpoint data for high-level business logic analysis.

* **Key Achievements:**
  * Integrated disparate relational databases—including case-handling systems, customer email repositories, and property metadata (Property ID, Property Name, City ID)—into a cohesive analytical data environment.
  * Formulated and embedded business logic to classify raw inquiry data by **Contact Type** (e.g., First Contact vs. Subsequent Contact) and **Urgency Level** (e.g., Check-in within 48h, Post Check-out, Check-in within 7 days).
  * Built flexible, multi-dimensional SQL querying capabilities to extract granular dataset segments across parameters like Contact Party, Case Reason, Date Period, and Urgency Level for strategic decision-making.

---

## 📊 Code & Logic Showcase

<details>
<summary><b>🔍 SQL Example: Multi-DB Join & Business Logic Categorization</b></summary>

```sql

case_tracker_enriched AS (
    -- Enrich raw tracker rows with:
    -- 1) year / quarter
    -- 2) subcase ranking within a case
    -- 3) ranking of cases within reservation + issue type
    -- 4) previous inbound status in the same flow
    -- 5) attachment presence flag
    SELECT
        ct.*,

        /* Time-derived helper fields */
        YEAR(tracker_created_at) AS yr,
        QUARTER(tracker_created_at) AS qtr,

        /* Rank subcases within the same case */
        DENSE_RANK() OVER (
            PARTITION BY case_id
            ORDER BY subcase_id
        ) AS subcase_rn,

        /* Rank cases within the same reservation + issue type */
        DENSE_RANK() OVER (
            PARTITION BY reservation_id, issue_type
            ORDER BY case_created_at
        ) AS rn_issue_case_reservation,

        /*
        Get the previous status within the same reservation / issue / original-record / tracker-type flow.
        This helps classify whether the current row is a follow-up, response, or subsequent contact.
        */
        LAG(case_status_flow, 1) OVER (
            PARTITION BY reservation_id, issue_type, is_original_record,
            CASE WHEN tracker_event_id > 0 THEN 1 ELSE 0 END
            ORDER BY case_id, tracker_sequence_in_case
        ) AS prev_subcase_status_inbound,

        /* Mark whether an attachment exists for the interaction */
        CASE
            WHEN interaction_id_ref IS NOT NULL THEN 1
            ELSE 0
        END AS has_attachment

    FROM support.fact_case_tracker ct
    LEFT JOIN attachment
        ON ct.conversation_id = UPPER(attachment.interaction_id_ref)
    WHERE product_type = 'Lodging'
      AND is_record_discarded = 0
      AND datamonth >= 202606
      AND tracker_created_at < CURRENT_DATE
),


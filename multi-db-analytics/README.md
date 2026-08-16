### Multi-DB Data Integration & Multi-Dimensional Analytics
> **Objective:** Unify fragmented operational databases to establish standardized customer touchpoint data for high-level business logic analysis.

* **Key Achievements:**
  * Integrated disparate relational databases—including case-handling systems, customer email repositories, and property metadata (Property ID, Property Name, City ID)—into a cohesive analytical data environment.
  * Formulated and embedded business logic to classify raw inquiry data by **Contact Type** (e.g., First Contact vs. Subsequent Contact) and **Urgency Level** (e.g., Check-in within 48h, Post Check-out, Check-in within 7 days).
  * Built flexible, multi-dimensional SQL querying capabilities to extract granular dataset segments across parameters like Contact Party, Case Reason, Date Period, and Urgency Level for strategic decision-making.

* **Purpose:**
  * Build a subcase-level analytical dataset from case-tracking records, 
  * then extract resolved email cases for a target issue type and attach message text.

* **Notes:**
  * All schema names, table names, column names, and labels are generalized.
  * The logic is preserved, but business-specific identifiers were anonymized.
  * This query is intended for SQL learning and portfolio documentation.
  * `query.sql` : Commented porfolio wersion of the anyonymized SQL query

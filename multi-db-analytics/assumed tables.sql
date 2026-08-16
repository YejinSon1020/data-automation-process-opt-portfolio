## Assumed Tables

### 1. `analytics.dim_date`

| Item | Value |
|---|---|
| Purpose | Date reference table used to define the analysis period |
| Grain | 1 row per date |

| Column Name | Meaning | Example |
|---|---|---|
| `calendar_date` | Calendar date used for filtering and joins | `2025-06-01` |

---

### 2. `support.interaction_attachment`

| Item | Value |
|---|---|
| Purpose | Raw attachment records linked to interactions |
| Grain | 1 row per attachment |

| Column Name | Meaning | Example |
|---|---|---|
| `interaction_id_ref` | Interaction identifier used to link attachments to conversations | `ABC123XYZ` |
| `attachment_mime_type` | MIME type of the attachment | `application/pdf` |
| `datamonth` | Data month in `YYYYMM` format | `202501` |

---

### 3. `analytics.fact_reservation`

| Item | Value |
|---|---|
| Purpose | Reservation-level booking data used for counts and local time calculations |
| Grain | 1 row per reservation |

| Column Name | Meaning | Example |
|---|---|---|
| `reservation_id` | Reservation identifier | `R123456` |
| `property_id` | Property identifier | `P1001` |
| `country_name` | Country name associated with the reservation/property | `Thailand` |
| `city_id` | City identifier | `20045` |
| `reservation_datetime_utc` | Reservation timestamp in UTC/reference timezone | `2025-06-01 10:00:00` |
| `reservation_datetime_local` | Reservation timestamp converted to local/property timezone | `2025-06-01 17:00:00` |
| `datamonth` | Data month in `YYYYMM` format | `202506` |

---

### 4. `support.fact_case_tracker`

| Item | Value |
|---|---|
| Purpose | Main operational tracking table for cases and subcases |
| Grain | 1 row per tracker event |

| Column Name | Meaning | Example |
|---|---|---|
| `tracker_event_id` | Tracker event identifier | `1245789` |
| `tracker_created_at` | Timestamp when the tracker row was created | `2025-06-20 14:05:00` |
| `case_id` | Case identifier | `C10001` |
| `subcase_id` | Subcase identifier | `SC10001` |
| `reservation_id` | Reservation identifier | `R123456` |
| `conversation_id` | Conversation identifier | `CONV001234` |
| `issue_type` | Contact / issue reason | `Property fees or surcharge request` |
| `case_created_at` | Case creation timestamp | `2025-06-20 14:00:00` |
| `case_status_flow` | Status trail / case flow label | `Follow up with Property` |
| `is_original_record` | Whether the record belongs to the original tracked flow | `1` |
| `tracker_sequence_in_case` | Sequence number within the case flow | `1` |
| `checkin_at` | Check-in datetime | `2025-06-25 15:00:00` |
| `checkout_at` | Check-out datetime | `2025-06-27 11:00:00` |
| `queue_started_at` | Queue start timestamp | `2025-06-20 14:02:00` |
| `subcase_started_at` | Subcase start timestamp | `2025-06-20 14:03:00` |
| `inbox_name` | Inbox or mailbox name | `support_inbox_a` |
| `contact_party` | Contact source/party | `Customer` |
| `contact_channel` | Channel of contact | `Email` |
| `contact_direction` | Inbound or outbound direction | `Inbound` |
| `partner_group` | Partner grouping label | `Direct` |
| `cancelled_at` | Cancellation timestamp | `2025-06-19 09:00:00` |
| `inbox_source` | Non-sensitive inbox source label | `support_inbox` |
| `property_country_name` | Property country name | `Thailand` |
| `property_id` | Property identifier | `P1001` |
| `queue_language` | Queue language | `ENGLISH` |
| `interaction_category_name` | Interaction category label | `PCM Email` |
| `interaction_resource_id` | Interaction resource identifier | `IRF001` |
| `product_type` | Product type | `Lodging` |
| `is_record_discarded` | Whether the record is discarded | `0` |
| `datamonth` | Data month in `YYYYMM` format | `202506` |

---

### 5. `analytics.dim_property`

| Item | Value |
|---|---|
| Purpose | Property reference table used for city-based joins |
| Grain | 1 row per property |

| Column Name | Meaning | Example |
|---|---|---|
| `property_id` | Property identifier | `P1001` |
| `city_id` | City identifier | `20045` |
| `property_name` | Property name | `Sample Riverside Hotel` |

---

### 6. `support.dim_interaction_user`

| Item | Value |
|---|---|
| Purpose | Interaction resource/user mapping table |
| Grain | 1 row per interaction resource |

| Column Name | Meaning | Example |
|---|---|---|
| `interaction_resource_id` | Interaction resource identifier | `IRF001` |
| `datamonth` | Data month in `YYYYMM` format | `202506` |

---

### 7. `support.fact_conversation`

| Item | Value |
|---|---|
| Purpose | Conversation-level text/body data used in the final output |
| Grain | 1 row per conversation |

| Column Name | Meaning | Example |
|---|---|---|
| `conversation_id` | Conversation identifier | `CONV001234` |
| `message_body` | Conversation/message text body | `Please confirm the surcharge amount...` |

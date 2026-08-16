/*
Generalized SQL Practice Query
------------------------------
Purpose:
Build a subcase-level analytical dataset from case-tracking records,
then extract resolved email cases for a target issue type and attach message text.

Notes:
- All schema names, table names, column names, and labels are generalized.
- The logic is preserved, but business-specific identifiers were anonymized.
- This query is intended for SQL learning and portfolio documentation.
*/

WITH dte AS (
    -- Define the target analysis date range
    SELECT calendar_date
    FROM analytics.dim_date
    WHERE calendar_date BETWEEN '2026-07-01' AND '2026-07-31' -- can change date
),

attachment AS (
    -- Aggregate raw attachment records to one row per interaction
    SELECT
        interaction_id_ref,
        COUNT(*) AS attachment_count
    FROM support.interaction_attachment
    WHERE datamonth >= 202606
      AND attachment_mime_type IS NOT NULL
    GROUP BY interaction_id_ref
),

fact_reservation_time AS (
    -- Build a country/city-level reference table:
    -- reservation volume + average local-vs-reference time difference
    SELECT
        country_name,
        city_id,
        COUNT(*) AS reservation_count,
        AVG(
            unix_timestamp(reservation_datetime_local)
            - unix_timestamp(r.reservation_datetime_utc)
        ) AS local_time_diff
    FROM analytics.fact_reservation r
    WHERE datamonth >= 202606
    GROUP BY country_name, city_id
),

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

subcase_data AS (
    -- Aggregate enriched tracker rows to the subcase level
    SELECT
        ct.yr,
        ct.qtr,
        issue_type,
        subcase_id,

        /* Representative identifiers */
        MIN(ct.reservation_id) AS reservation_id,
        MIN(case_id) AS case_id,
        MIN(CASE WHEN tracker_event_id > 0 THEN conversation_id END) AS conversation_id,

        /*
        Lead-time bucket:
        Classify the interaction timing relative to check-in/check-out,
        using a local-time adjustment when available.
        */
        MIN(
            CASE
                WHEN tracker_event_id < 0 THEN NULL

                WHEN unix_timestamp(checkout_at)
                     - (
                        unix_timestamp(COALESCE(queue_started_at, subcase_started_at))
                        + COALESCE(rt.local_time_diff, 0)
                       ) < -24 * 3600
                    THEN '1. After check-out date'

                WHEN unix_timestamp(checkin_at)
                     - (
                        unix_timestamp(COALESCE(queue_started_at, subcase_started_at))
                        + COALESCE(rt.local_time_diff, 0)
                       ) < 6 * 3600
                    THEN '2. 6 hrs before check-in to during stay'

                WHEN unix_timestamp(checkin_at)
                     - (
                        unix_timestamp(COALESCE(queue_started_at, subcase_started_at))
                        + COALESCE(rt.local_time_diff, 0)
                       ) < 24 * 3600
                    THEN '3. 6-24 hrs before check-in (midnight local)'

                WHEN unix_timestamp(checkin_at)
                     - (
                        unix_timestamp(COALESCE(queue_started_at, subcase_started_at))
                        + COALESCE(rt.local_time_diff, 0)
                       ) < 48 * 3600
                    THEN '4. 24-48 hrs before check-in (midnight local)'

                WHEN unix_timestamp(checkin_at)
                     - (
                        unix_timestamp(COALESCE(queue_started_at, subcase_started_at))
                        + COALESCE(rt.local_time_diff, 0)
                       ) >= 48 * 3600
                    THEN '5. >48 hrs before check-in (midnight local)'
            END
        ) AS checkin_leadtime,

        /*
        Contact flow classification:
        Translate raw case-flow context into operational categories.
        */
        MIN(
            CASE
                WHEN tracker_event_id < 0 THEN NULL

                WHEN is_original_record = 0
                    THEN 'Untracked'

                WHEN subcase_rn = 1 AND rn_issue_case_reservation = 1
                    THEN 'First contact of issue type'

                WHEN subcase_rn = 1
                    THEN 'Follow-up contact (Recontact)'

                WHEN prev_subcase_status_inbound IN (
                        'Follow up with Property',
                        'Follow up with Partner',
                        'Follow up with Customer',
                        'Follow up with Business Partner',
                        'Awaiting Customer Response'
                     )
                     AND contact_party IN ('Customer', 'B2B')
                    THEN 'Customer subsequent'

                WHEN prev_subcase_status_inbound IN (
                        'Follow up with Property',
                        'Follow up with Partner'
                     )
                     AND contact_party IN ('Property', 'Partner')
                    THEN 'Partner responded (Pending Property/Partner)'

                WHEN prev_subcase_status_inbound IN (
                        'Follow up with Customer',
                        'Follow up with Business Partner',
                        'Awaiting Customer Response'
                     )
                     AND contact_party IN ('Customer', 'B2B')
                    THEN 'Customer responded (Pending Customer/B2B)'

                WHEN interaction_category_name RLIKE 'PCM'
                    THEN 'Priority Category Email'

                WHEN tracker_event_id > 0
                    THEN 'Others'
            END
        ) AS contact_flow_type,

        /* Representative descriptive attributes from tracked rows */
        MIN(CASE WHEN tracker_event_id > 0 THEN inbox_name END) AS inbox_name,
        MIN(CASE WHEN tracker_event_id > 0 THEN contact_party END) AS contact_party,
        MIN(CASE WHEN tracker_event_id > 0 THEN contact_channel END) AS contact_channel,

        /* Outbound-related flags */
        MIN(CASE WHEN contact_direction = 'Outbound' AND contact_channel = 'Voice' THEN 1 ELSE 0 END) AS is_outbound_voice,
        MIN(CASE WHEN contact_direction = 'Outbound' AND contact_channel = 'Email' THEN 1 ELSE 0 END) AS is_outbound_email,

        /* Basic operational measures */
        SUM(CASE WHEN tracker_event_id > 0 THEN 1 END) AS subcase_count,
        SUM(CASE WHEN tracker_event_id < 0 THEN 1 ELSE 0 END) AS outbound_tracker_count,
        SUM(CASE WHEN conversation_id = 'AUTO-BOT' THEN 1 END) AS automated_subcase_count,

        /* Additional helper fields */
        MAX(has_attachment) AS has_attachment,
        MIN(
            CASE
                WHEN tracker_sequence_in_case = 1 THEN 'Is first contact of reservation'
                ELSE 'Other'
            END
        ) AS is_first_subcase,
        MIN(tracker_created_at) AS tracker_created_at,

        MAX(
            CASE
                WHEN cancelled_at > '2000-01-01'
                 AND cancelled_at < case_created_at
                    THEN 'Cancel before case creation'
                ELSE 'Other'
            END
        ) AS is_cancellation_before_case,

        MAX(CASE WHEN case_status_flow = 'Resolved' THEN 1 ELSE 0 END) AS is_resolved,
        MIN(inbox_source) AS inbox_source

    FROM case_tracker_enriched ct

    -- Restrict the dataset to the target analysis dates
    INNER JOIN dte
        ON TO_DATE(tracker_created_at) = dte.calendar_date

    -- Add property metadata for city-based joins
    LEFT JOIN analytics.dim_property p
        ON ct.property_id = p.property_id

    -- Add local time-difference reference at the country/city level
    LEFT JOIN fact_reservation_time rt
        ON ct.property_country_name = rt.country_name
       AND p.city_id = rt.city_id

    -- Add interaction user/resource mapping
    LEFT JOIN support.dim_interaction_user iu
        ON ct.interaction_resource_id = iu.interaction_resource_id
       AND iu.datamonth >= 202606

    WHERE queue_language = 'ENGLISH'

    -- One row per year / quarter / issue type / subcase
    GROUP BY 1, 2, 3, 4
)

-- Final extraction query:
-- Return resolved email subcases for a target issue type,
-- classified as first contact of issue type,
-- with message text attached for content review.
SELECT
    s.reservation_id,
    s.case_id,
    s.subcase_id,
    s.issue_type,
    s.contact_flow_type,
    fc.message_body
FROM subcase_data s
INNER JOIN support.fact_conversation fc
    ON s.conversation_id = fc.conversation_id
WHERE 1 = 1
  AND s.contact_flow_type = 'First contact of issue type'
  AND s.contact_channel = 'Email'
  -- AND s.issue_type = 'Property fees or surcharge request'
  AND s.is_resolved = 1;

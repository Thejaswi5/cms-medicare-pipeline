{{ config(materialized='view') }}

-- STAGING MODEL: stg_financials
-- Purpose: Clean and standardize raw financial data
-- Source: raw.financials (loaded by load_data.py)
-- Consumers: int_sector_performance, mart_company_analysis
-- Refresh: On demand when new quarterly data arrives

WITH source AS (
    -- Reference raw source table
    -- Never hardcode table names in dbt
    SELECT * FROM {{ source('raw', 'financials') }}
),

cleaned AS (
    SELECT
        -- Company identifiers
        UPPER(ticker) AS ticker,
        company_name,
        sector,
        period,

        -- Extract year and quarter for easier filtering
        SPLIT_PART(period, '-', 1)::INTEGER AS year,
        SPLIT_PART(period, '-', 2) AS quarter,

        -- Financial metrics
        ROUND(revenue_bn, 2) AS revenue_bn,
        ROUND(net_income_bn, 2) AS net_income_bn,
        ROUND(operating_expense_bn, 2) AS operating_expense_bn,
        ROUND(total_debt_bn, 2) AS total_debt_bn,
        ROUND(eps, 2) AS eps,
        ROUND(profit_margin_pct, 2) AS profit_margin_pct,
        ROUND(revenue_growth_pct, 2) AS revenue_growth_pct,

        -- Derived metric: debt burden relative to revenue
        ROUND(
            total_debt_bn / NULLIF(revenue_bn, 0),
        2) AS debt_to_revenue_ratio,

        -- Data quality flag
        CASE
            WHEN revenue_bn <= 0 THEN 'invalid_revenue'
            WHEN net_income_bn IS NULL THEN 'missing_income'
            WHEN ticker IS NULL THEN 'missing_ticker'
            ELSE 'valid'
        END AS record_status

    FROM source
)

-- Only pass valid records downstream
SELECT * FROM cleaned
WHERE record_status = 'valid'
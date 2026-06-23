{{ config(materialized='table') }}

-- MART MODEL: mart_company_analysis
-- Purpose: Company performance summary for analysts and dashboards
-- Source: stg_financials
-- Consumers: Power BI dashboards, analyst SQL queries
-- Refresh: Daily via Airflow DAG (future)
-- Owner: Data Engineering team

WITH annual_metrics AS (
    SELECT
        ticker,
        company_name,
        sector,
        year,

        -- Annual aggregations from quarterly data
        ROUND(SUM(revenue_bn), 2) AS annual_revenue_bn,
        ROUND(SUM(net_income_bn), 2) AS annual_net_income_bn,
        ROUND(AVG(profit_margin_pct), 2) AS avg_profit_margin,
        ROUND(AVG(revenue_growth_pct), 2) AS avg_revenue_growth,
        ROUND(AVG(debt_to_revenue_ratio), 2) AS avg_debt_ratio,
        ROUND(AVG(eps), 2) AS avg_eps,
        ROUND(MAX(revenue_bn), 2) AS best_quarter_revenue,
        ROUND(MIN(revenue_bn), 2) AS worst_quarter_revenue,
        COUNT(*) AS quarters_reported

    FROM {{ ref('stg_financials') }}
    GROUP BY ticker, company_name, sector, year
),

with_rankings AS (
    SELECT
        *,

        -- Rank within sector per year
        -- Who is the most profitable company in their sector?
        RANK() OVER (
            PARTITION BY sector, year
            ORDER BY avg_profit_margin DESC
        ) AS sector_profitability_rank,

        -- Rank by revenue across all companies per year
        -- Who are the biggest companies overall?
        RANK() OVER (
            PARTITION BY year
            ORDER BY annual_revenue_bn DESC
        ) AS overall_revenue_rank,

        -- Revenue volatility — difference between best and worst quarter
        -- High volatility = risky, low volatility = stable
        ROUND(best_quarter_revenue - worst_quarter_revenue, 2)
            AS revenue_volatility,

        -- Year over year revenue change
        -- Compare this year to prior year for same company
        ROUND(annual_revenue_bn - LAG(annual_revenue_bn) OVER (
            PARTITION BY ticker
            ORDER BY year
        ), 2) AS yoy_revenue_change

    FROM annual_metrics
),

final AS (
    SELECT
        *,
        -- Is this company the top performer in their sector?
        CASE
            WHEN sector_profitability_rank = 1 THEN true
            ELSE false
        END AS is_sector_leader,

        -- Performance tier based on margin
        CASE
            WHEN avg_profit_margin >= 30 THEN 'High Performer'
            WHEN avg_profit_margin >= 15 THEN 'Mid Performer'
            ELSE 'Low Performer'
        END AS performance_tier

    FROM with_rankings
)

SELECT * FROM final
ORDER BY year DESC, sector, sector_profitability_rank

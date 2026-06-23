{{ config(materialized='view') }}

-- INTERMEDIATE MODEL: int_sector_performance
-- Purpose: Aggregate company metrics to sector level
-- Source: stg_financials
-- Consumers: mart_company_analysis
-- Business question: How is each sector performing per quarter?

WITH quarterly_sector AS (
    SELECT
        sector,
        period,
        year,
        quarter,

        -- Aggregate all companies within sector
        COUNT(DISTINCT ticker) AS company_count,
        ROUND(AVG(revenue_bn), 2) AS avg_revenue_bn,
        ROUND(AVG(net_income_bn), 2) AS avg_net_income_bn,
        ROUND(SUM(revenue_bn), 2) AS total_sector_revenue,
        ROUND(AVG(profit_margin_pct), 2) AS avg_profit_margin,
        ROUND(AVG(revenue_growth_pct), 2) AS avg_revenue_growth,
        ROUND(AVG(debt_to_revenue_ratio), 2) AS avg_debt_ratio,
        ROUND(MAX(profit_margin_pct), 2) AS best_margin_in_sector,
        ROUND(MIN(profit_margin_pct), 2) AS worst_margin_in_sector

    FROM {{ ref('stg_financials') }}
    GROUP BY sector, period, year, quarter
),

with_rankings AS (
    SELECT
        *,

        -- Which sector is most profitable this quarter?
        RANK() OVER (
            PARTITION BY period
            ORDER BY avg_profit_margin DESC
        ) AS profitability_rank,

        -- Which sector is growing fastest this quarter?
        RANK() OVER (
            PARTITION BY period
            ORDER BY avg_revenue_growth DESC
        ) AS growth_rank,

        -- Running cumulative revenue per sector over time
        -- Shows long term trajectory of each sector
        ROUND(SUM(total_sector_revenue) OVER (
            PARTITION BY sector
            ORDER BY year, quarter
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ), 2) AS cumulative_revenue

    FROM quarterly_sector
)

SELECT * FROM with_rankings
ORDER BY period, profitability_rank

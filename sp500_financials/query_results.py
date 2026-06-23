import duckdb

con = duckdb.connect("financial.duckdb")

print("=" * 50)
print("TOP COMPANIES BY PROFIT MARGIN 2023")
print("=" * 50)
result = con.execute("""
    SELECT ticker, company_name, sector,
           avg_profit_margin, performance_tier,
           is_sector_leader
    FROM main.mart_company_analysis
    WHERE year = 2023
    ORDER BY avg_profit_margin DESC
    LIMIT 10
""").fetchall()
for row in result:
    print(f"  {row[0]} | {row[2]} | {row[3]}% | {row[4]} | Leader:{row[5]}")

print("\n" + "=" * 50)
print("BEST SECTORS 2023")
print("=" * 50)
result = con.execute("""
    SELECT sector,
           ROUND(AVG(avg_profit_margin),2) AS margin,
           ROUND(SUM(annual_revenue_bn),2) AS revenue
    FROM main.mart_company_analysis
    WHERE year = 2023
    GROUP BY sector
    ORDER BY margin DESC
""").fetchall()
for i, row in enumerate(result, 1):
    print(f"  {i}. {row[0]} | Margin:{row[1]}% | Revenue:${row[2]}B")

print("\n" + "=" * 50)
print("SECTOR LEADERS ACROSS ALL YEARS")
print("=" * 50)
result = con.execute("""
    SELECT year, sector, ticker,
           avg_profit_margin, performance_tier
    FROM main.mart_company_analysis
    WHERE is_sector_leader = true
    ORDER BY year, sector
""").fetchall()
for row in result:
    print(f"  {row[0]} | {row[1]} | {row[2]} | {row[3]}% | {row[4]}")

con.close()
print("\nDone.")
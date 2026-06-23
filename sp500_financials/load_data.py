import duckdb
import random
import csv

print("Step 1: Starting...")

random.seed(42)
rows = []

companies = [
    ("AAPL", "Apple Inc", "Technology"),
    ("MSFT", "Microsoft Corp", "Technology"),
    ("JPM", "JPMorgan Chase", "Financials"),
    ("BAC", "Bank of America", "Financials"),
    ("JNJ", "Johnson & Johnson", "Healthcare"),
    ("PFE", "Pfizer Inc", "Healthcare"),
    ("XOM", "Exxon Mobil", "Energy"),
    ("WMT", "Walmart Inc", "Consumer Staples"),
    ("TSLA", "Tesla Inc", "Technology"),
    ("NVDA", "NVIDIA Corp", "Technology"),
]

quarters = ["2021-Q1","2021-Q2","2021-Q3","2021-Q4",
            "2022-Q1","2022-Q2","2022-Q3","2022-Q4",
            "2023-Q1","2023-Q2","2023-Q3","2023-Q4"]

print("Step 2: Generating data...")

for ticker, name, sector in companies:
    revenue = random.uniform(10, 100)
    for period in quarters:
        growth = random.uniform(-0.08, 0.15)
        revenue = round(revenue * (1 + growth), 2)
        margin = random.uniform(0.08, 0.40)
        net_income = round(revenue * margin, 2)
        rows.append({
            "ticker": ticker,
            "company_name": name,
            "sector": sector,
            "period": period,
            "revenue_bn": revenue,
            "net_income_bn": net_income,
            "operating_expense_bn": round(revenue * random.uniform(0.55, 0.85), 2),
            "profit_margin_pct": round(margin * 100, 2),
            "revenue_growth_pct": round(growth * 100, 2),
            "total_debt_bn": round(revenue * random.uniform(0.5, 3.0), 2),
            "eps": round(net_income / random.uniform(1, 15), 2),
        })

print(f"Step 3: Generated {len(rows)} rows")

with open("financial_data.csv", "w", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=rows[0].keys())
    writer.writeheader()
    writer.writerows(rows)

print("Step 4: CSV saved")

con = duckdb.connect("financial.duckdb")
con.execute("CREATE SCHEMA IF NOT EXISTS raw")
con.execute("""
    CREATE OR REPLACE TABLE raw.financials AS
    SELECT * FROM read_csv_auto('financial_data.csv')
""")

count = con.execute("SELECT COUNT(*) FROM raw.financials").fetchone()[0]
print(f"Step 5: Loaded {count:,} rows into raw.financials")

cols = con.execute("DESCRIBE raw.financials").fetchall()
print("\nColumns:")
for col in cols:
    print(f"  {col[0]} — {col[1]}")

con.close()
print("\nDone!")
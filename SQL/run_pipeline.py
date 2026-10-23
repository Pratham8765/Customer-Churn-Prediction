#!/usr/bin/env python3
"""Load the Telco churn CSV into SQLite, clean it with SQL, run the analysis queries,
and export CSVs for Power BI.

Usage:
    python run_pipeline.py customer_churn.csv
    python run_pipeline.py customer_churn.csv --db churn.db --out .
"""
import argparse
import re
import sqlite3
import sys
from pathlib import Path

import pandas as pd

SQL_DIR = Path(__file__).parent / "sql"
if not (SQL_DIR / "01_clean.sql").exists():      # script placed inside the sql/ folder
    SQL_DIR = Path(__file__).parent

REQUIRED_COLUMNS = {
    "customerID", "gender", "SeniorCitizen", "Partner", "Dependents", "tenure",
    "PhoneService", "MultipleLines", "InternetService", "OnlineSecurity", "OnlineBackup",
    "DeviceProtection", "TechSupport", "StreamingTV", "StreamingMovies", "Contract",
    "PaperlessBilling", "PaymentMethod", "MonthlyCharges", "TotalCharges", "Churn",
}


def read_named_queries(path):
    """Split a .sql file into (name, query) pairs using '-- name: xxx' marker lines."""
    text = path.read_text(encoding="utf-8")
    parts = re.split(r"^--\s*name:\s*(\w+)\s*$", text, flags=re.MULTILINE)
    return [(parts[i], parts[i + 1].strip()) for i in range(1, len(parts), 2)]


def run_named(con, sql_file, out_dir=None):
    for name, query in read_named_queries(SQL_DIR / sql_file):
        df = pd.read_sql_query(query, con)
        print(f"\n== {name} ==")
        print(df.to_string(index=False) if len(df) else "(no rows)")
        if out_dir is not None:
            df.to_csv(out_dir / f"{name}.csv", index=False)


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("csv_path", help="path to customer_churn.csv")
    ap.add_argument("--db", default="churn.db", help="SQLite file to create")
    ap.add_argument("--out", default=".", help="folder for results/ and powerbi_data/")
    args = ap.parse_args()

    if sqlite3.sqlite_version_info < (3, 25, 0):
        sys.exit(f"SQLite {sqlite3.sqlite_version} is too old for window functions (need 3.25+).")

    # Load everything as text so the SQL layer does the typing and cleaning.
    df = pd.read_csv(args.csv_path, dtype=str, keep_default_na=False)
    missing = REQUIRED_COLUMNS - set(df.columns)
    if missing:
        sys.exit(f"CSV is missing expected columns: {sorted(missing)}")

    out = Path(args.out)
    results_dir = out / "results"
    powerbi_dir = out / "powerbi_data"
    results_dir.mkdir(parents=True, exist_ok=True)
    powerbi_dir.mkdir(parents=True, exist_ok=True)

    con = sqlite3.connect(args.db)
    df.to_sql("raw_customers", con, if_exists="replace", index=False)
    print(f"Loaded {len(df)} rows into raw_customers ({args.db})")

    print("\n##### DATA QUALITY #####")
    run_named(con, "00_data_quality.sql")

    print("\n##### CLEAN #####")
    con.executescript((SQL_DIR / "01_clean.sql").read_text(encoding="utf-8"))
    n = con.execute("SELECT COUNT(*) FROM customers").fetchone()[0]
    print(f"customers table built: {n} rows")

    print("\n##### ANALYSIS #####")
    run_named(con, "02_analysis.sql", results_dir)

    print("\n##### VIEWS + POWER BI EXPORT #####")
    con.executescript((SQL_DIR / "03_views.sql").read_text(encoding="utf-8"))
    pd.read_sql_query("SELECT * FROM vw_customers_powerbi", con).to_csv(
        powerbi_dir / "customers.csv", index=False)
    pd.read_sql_query("SELECT * FROM vw_churn_summary", con).to_csv(
        powerbi_dir / "churn_summary.csv", index=False)
    print(f"Wrote {powerbi_dir}/customers.csv and churn_summary.csv")
    con.close()


if __name__ == "__main__":
    main()

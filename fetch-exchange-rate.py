#!/usr/bin/env python3
"""
Fetch USD/PLN exchange rate from NBP API and update invoice-data.toml
"""

import tomllib
import json
import urllib.request
import urllib.error
from datetime import datetime, timedelta
import re
import sys
import os
from typing import Tuple, Optional, Any, Dict


def fetch_nbp_exchange_rate(date_str: str) -> Optional[Tuple[float, str]]:
    """
    Fetch USD/PLN exchange rate from NBP API for given date
    Returns tuple (rate, date_str) or None if not found
    """
    url: str = f"https://api.nbp.pl/api/exchangerates/rates/a/usd/{date_str}/"

    try:
        with urllib.request.urlopen(url) as response:
            data: Dict[str, Any] = json.loads(response.read().decode())
            rate: float = data["rates"][0]["mid"]
            effective_date: str = data["rates"][0]["effectiveDate"]
            return rate, effective_date
    except urllib.error.HTTPError as e:
        if e.code == 404:
            # No data for this date (weekend/holiday)
            return None
        else:
            print(f"Error fetching exchange rate: {e}")
            sys.exit(1)
    except Exception as e:
        print(f"Unexpected error: {e}")
        sys.exit(1)


def find_exchange_rate(start_date: datetime) -> Tuple[float, str]:
    """
    Find exchange rate by trying consecutive previous days
    Returns tuple: (rate, date_str)
    """
    current_date: datetime = start_date
    max_attempts: int = 10  # Don't go back more than 10 days

    for _ in range(max_attempts):
        date_str: str = current_date.strftime("%Y-%m-%d")
        print(f"Trying to fetch exchange rate for {date_str}...")

        result = fetch_nbp_exchange_rate(date_str)
        if result is not None:
            rate, effective_date = result
            print(f"Found exchange rate: {rate} PLN/USD for {effective_date}")
            return rate, effective_date

        # Try previous day
        current_date = current_date - timedelta(days=1)

    print(f"Error: Couldn't find exchange rate in the last {max_attempts} days")
    sys.exit(1)


def update_toml_file(filename: str, exchange_rate: float, exchange_date: str) -> None:
    """
    Update the TOML file with new exchange rate and date
    Uses regex to preserve formatting and comments
    """
    with open(filename, "r") as f:
        content: str = f.read()

    new_content, rate_count = re.subn(
        r"^exchange_rate = .*$",
        f"exchange_rate = {exchange_rate}  # fetch-exchange-rate.py",
        content,
        flags=re.MULTILINE,
    )
    new_content, date_count = re.subn(
        r"^exchange_date = .*$",
        f'exchange_date = "{exchange_date}"  # fetch-exchange-rate.py',
        new_content,
        flags=re.MULTILINE,
    )

    if rate_count == 0 or date_count == 0:
        print("Error: Could not find exchange_rate or exchange_date in TOML file")
        print("Please check that invoice-data.toml has the correct format")
        sys.exit(1)

    with open(filename, "w") as f:
        f.write(new_content)

    print(f"✓ Updated {filename}")


def main() -> None:
    # Query-only mode: if date argument provided, fetch rate without updating TOML
    if len(sys.argv) > 1:
        date_str = sys.argv[1]
        query_date = datetime.strptime(date_str, "%Y-%m-%d")
        start_date = query_date - timedelta(days=1)
        print(f"Looking for exchange rate before {date_str}...")
        rate, effective_date = find_exchange_rate(start_date)

        print("\n")
        print(f"Exchange rate for {effective_date}:")
        print(f"Rate: {rate} PLN/USD")
        return

    # Normal mode: update invoice-data.toml
    toml_file: str = "invoice-data.toml"

    if not os.path.exists(toml_file):
        print(f"Error: {toml_file} not found.")
        print("Run 'make' to create it from the template.")
        sys.exit(1)

    # Read current invoice data
    print(f"Reading {toml_file}...")
    with open(toml_file, "rb") as f:
        data: Dict[str, Any] = tomllib.load(f)

    # Parse invoice date
    invoice_date_str: str = data["invoice_date"]
    invoice_date: datetime = datetime.strptime(invoice_date_str, "%Y-%m-%d")
    print(f"Invoice date: {invoice_date_str}")

    # Start from the day before invoice date and find the most recent rate
    start_date: datetime = invoice_date - timedelta(days=1)
    print(f"Looking for exchange rate before {invoice_date_str}...")

    # Fetch exchange rate (will try previous days until one is found)
    rate, effective_date = find_exchange_rate(start_date)

    # Update TOML file
    update_toml_file(toml_file, rate, effective_date)

    print("\n")
    print(f"Success! Exchange rate updated:")  # noqa: F541
    print(f"Rate: {rate} PLN/USD")
    print(f"Date: {effective_date}")


if __name__ == "__main__":
    main()

# Invoice Generator

**Personal project** for generating *my* invoices.

Generates professional bilingual invoices (English/Polish) in PDF format with
automatic USD/PLN exchange rates from the Polish National Bank (NBP).

**[View sample PDF]**

## Quick Start

1.  **Enter development environment:**

    ``` bash
    nix develop
    ```

2.  **Generate your first invoice:**

    ``` bash
    make
    ```

    This creates `invoice-data.toml` from the template. Edit it with your data,
    then run `make` again.

## Features

- **Dual currency**: Automatic USD to PLN conversion using real NBP exchange
  rates
- **Bilingual**: English with Polish translations
- **Secure**: Sensitive data stays local (gitignored)
- **Automated**: Single `make` command fetches rates and generates PDF

## Configuration

Edit `invoice-data.toml` with your:

- Invoice details (date, number)
- Seller/buyer information
- Bank details
- Invoice items

Exchange rates are fetched automatically—don't edit them manually.

## Common Commands

- `make` - Generate invoice PDF
- `make clean` - Remove generated files
- `python3 fetch-exchange-rate.py YYYY-MM-DD` - Query exchange rate for a
  specific date

## Requirements

- Nix (manages all dependencies)

- Or: Python 3.11+, Typst, pre-commit (if not using Nix)

  [View sample PDF]: https://github.com/jupblb/invoice/releases/download/latest/invoice.pdf

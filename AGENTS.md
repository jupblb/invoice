# AGENTS.md

## Project Overview

This project generates invoices in PDF format using Typst, with automatic
USD/PLN exchange rate fetching from the Polish National Bank (NBP) API.

## Project Setup

This project uses **Nix** to manage all program dependencies and development
environment. The `flake.nix` file defines the development shell and all required
packages (Typst, Python 3.13, pre-commit hooks).

## Getting Started

1.  Enter the development environment:

    ``` bash
    nix develop
    # Or if using direnv:
    direnv allow
    ```

2.  Create your invoice configuration:

    ``` bash
    # On first run, the Makefile will copy the template
    make
    # This creates invoice-data.toml from invoice-data.toml.tmpl
    # Edit invoice-data.toml with your actual data
    ```

3.  Generate invoice:

    ``` bash
    make  # Fetches exchange rate and compiles PDF
    ```

## Common Commands

### Build Commands (Makefile)

- `make` or `make invoice.pdf` - Fetch exchange rate from NBP and compile
  invoice PDF
- `make fetch` - Only fetch exchange rate and update invoice-data.toml
- `make clean` - Remove generated invoice.pdf and invoice.png

### Exchange Rate Script

- `python3 fetch-exchange-rate.py` - Update exchange rate in invoice-data.toml
  from NBP API
- `python3 fetch-exchange-rate.py 2024-12-27` - Query exchange rate for specific
  date (read-only)

### Typst Commands

- `typst compile invoice.typ` - Compile invoice to PDF
- `typst compile invoice.typ invoice.png` - Generate PNG for quality
  verification
- `typstyle -i invoice.typ` - Format Typst file in place

### Pre-commit Hooks

- `pre-commit install` - Install git hooks
- `pre-commit run --all-files` - Run all hooks on all files
- `pre-commit run typstyle` - Run typstyle formatter on staged Typst files
- `pre-commit run pandoc` - Run pandoc formatter on staged markdown files

### Nix/Development Environment

- `nix develop` - Enter development shell with all dependencies
- `nix flake update` - Update all flake inputs to latest versions
- `nix flake lock` - Update flake.lock file

## Project Structure

    /
    ├── .github/
    │   └── workflows/
    │       ├── pre-commit.yml           # CI for pre-commit checks
    │       └── generate-sample-invoice.yml  # Generate sample PDF from template
    ├── flake.nix                  # Nix flake configuration defining dependencies
    ├── flake.lock                 # Locked versions of dependencies
    ├── invoice.typ                # Typst invoice template
    ├── invoice-data.toml          # Invoice configuration (gitignored, contains sensitive data)
    ├── invoice-data.toml.tmpl     # Template for invoice-data.toml
    ├── fetch-exchange-rate.py     # Python script to fetch USD/PLN rate from NBP API
    ├── Makefile                   # Build automation
    ├── .pre-commit-config.yaml    # Pre-commit hook configuration
    ├── .gitignore                 # Git ignore patterns
    ├── .direnv/                   # Direnv cache (auto-loads nix shell)
    ├── invoice.pdf                # Generated invoice (gitignored)
    └── invoice.png                # Generated screenshot (gitignored)

## Configuration

### invoice-data.toml

This file contains all invoice-specific data:

- Invoice date and number
- Seller information (name, address, tax ID)
- Buyer information
- Bank details (IBAN, SWIFT)
- Invoice items (service name, quantity, price, VAT rate)
- Exchange rate and date (auto-updated by fetch-exchange-rate.py)

**Note**: This file is gitignored and contains sensitive information. Use
`invoice-data.toml.tmpl` as a template to create it.

### Exchange Rate Fetching

The `fetch-exchange-rate.py` script:

- Reads invoice_date from invoice-data.toml
- Calculates the previous workday
- Fetches USD/PLN exchange rate from NBP API for that date
- Handles weekends and Polish holidays by trying consecutive previous days
- Updates invoice-data.toml with the fetched rate and date
- Zero dependencies - uses only Python 3.13 standard library

## Invoice Features

- **Dual currency**: Shows prices in both USD and PLN
- **Automatic exchange rates**: Fetches current NBP rates
- **Bilingual**: English with Polish translations
- **Professional formatting**: Clean table layout with proper number formatting
- **VAT support**: Handles reverse charge (0% VAT) with footnote

## GitHub Actions

### Pre-commit Checks (`.github/workflows/pre-commit.yml`)

Runs on pull requests and pushes to main:

- Executes all pre-commit hooks (typstyle, pandoc)
- Uses self-hosted runners
- Ensures code quality before merging

### Sample Invoice Generation (`.github/workflows/generate-sample-invoice.yml`)

Runs on workflow dispatch (manual) and when invoice files change:

- Generates invoice PDF from template file
- Fetches real exchange rates from NBP API
- Uploads PDF as downloadable artifact
- Uses self-hosted runners
- Safe for public repos (uses template, no sensitive data)

## Notes for AI Agents

- All dependencies are managed through Nix, not language-specific package
  managers
- The development environment is reproducible across different machines
- Check `flake.nix` for available packages and development tools
- `invoice-data.toml` contains sensitive information and should never be
  committed
- Exchange rates are fetched automatically - don't manually edit exchange_rate
  or exchange_date in the TOML
- The Makefile handles the full build workflow: template → data file → fetch
  rate → compile PDF
- **IMPORTANT**: Update this AGENTS.md file after each major change to project
  infrastructure (dependencies, build tools, testing frameworks, etc.)

#set page(
  paper: "a4",
  margin: (x: 2.5cm, y: 2cm),
)

#set text(
  font: ("Helvetica", "Liberation Sans", "Arial"),
  size: 10pt,
)

#set par(
  justify: false,
  leading: 0.65em,
)

#let get_previous_workday(date) = {
  let prev = date - duration(days: 1)
  while prev.weekday() == 6 or prev.weekday() == 7 {
    prev = prev - duration(days: 1)
  }
  prev
}

#let invoice_data = toml("invoice-data.toml")

// Parse invoice date from ISO string (YYYY-MM-DD)
#let date_parts = invoice_data.invoice_date.split("-")
#let invoice_date = datetime(
  year: int(date_parts.at(0)),
  month: int(date_parts.at(1)),
  day: int(date_parts.at(2)),
)
#let invoice_number = invoice_data.invoice_number

// Use exchange rate from TOML (will be auto-updated by fetch script)
#let exchange_rate = invoice_data.exchange_rate
#let exchange_date_parts = invoice_data.exchange_date.split("-")
#let exchange_date = datetime(
  year: int(exchange_date_parts.at(0)),
  month: int(exchange_date_parts.at(1)),
  day: int(exchange_date_parts.at(2)),
)

#let seller = invoice_data.seller
#let buyer = invoice_data.buyer
#let bank = invoice_data.bank
#let items = invoice_data.items

#let format_number(n) = {
  let s = str(n)
  if not s.contains(".") { s = s + ".00" }
  let parts = s.split(".")
  let int = parts.at(0)
  let frac = if parts.len() > 1 { parts.at(1) } else { "00" }
  if frac.len() == 1 { frac = frac + "0" }
  if frac.len() > 2 { frac = frac.slice(0, 2) }

  let sign = ""
  if int.starts-with("-") {
    sign = "-"
    int = int.slice(1)
  }
  let grouped = ""
  while int.len() > 3 {
    grouped = "," + int.slice(-3) + grouped
    int = int.slice(0, -3)
  }
  sign + int + grouped + "." + frac
}

#let format_usd(n) = "$" + format_number(n)
#let format_pln(n) = format_number(n) + " PLN"

// Format invoice number as: number/month/year
#let format_invoice_number(num, date) = {
  "FV/" + date.display("[year]/[month padding:zero]/") + str(num)
}

// Document content starts here
#align(right)[
  #text(size: 10pt)[
    Date of issue (data wystawienia):
    #invoice_date.display("[year]-[month]-[day]")
  ]
  \
  #text(size: 10pt)[
    Date of sale (data sprzedaży):
    #invoice_date.display("[year]-[month]-[day]")
  ]
]

#v(0.5em)

#block(
  fill: rgb(240, 130, 60),
  width: 100%,
  inset: 10pt,
)[
  #align(center)[
    #text(size: 18pt, weight: "bold")[
      Invoice (faktura)
      #format_invoice_number(invoice_number, invoice_date)
    ]
  ]
]

#v(1em)

// Seller and Buyer section
#grid(
  columns: (1fr, 1fr),
  gutter: 1em,
  [
    #text(weight: "bold")[Seller] #text(size: 9pt)[(sprzedawca)]: \
    #v(-0.5em)
    #line(length: 100%, stroke: 0.5pt)
    #v(-0.5em)
    #seller.name \
    #seller.address_line1 \
    #seller.address_line2 \
    #seller.country #text(size: 9pt)[(#seller.country_pl)] \
    #if seller.tax_id != "" [
      #text(weight: "bold")[Tax ID] #text(size: 9pt)[(NIP)]: #seller.tax_id
    ]
  ],
  [
    #text(weight: "bold")[Buyer] #text(size: 9pt)[(nabywca)]: \
    #v(-0.5em)
    #line(length: 100%, stroke: 0.5pt)
    #v(-0.5em)
    #buyer.name \
    #buyer.address_line1 \
    #buyer.address_line2 \
    #buyer.country #text(size: 9pt)[(#buyer.country_pl)]
  ],
)

#v(1em)

// Bank account details
Bank account #text(size: 9pt)[(konto bankowe)]:
#v(-0.6em)
#grid(
  columns: (auto, auto),
  column-gutter: 0.5em,
  row-gutter: 0.65em,
  [IBAN:], [#text(weight: "bold")[#bank.iban]],
  [BIC/SWIFT:], [#text(weight: "bold")[#bank.swift]],
  [Bank name:], [#text(weight: "bold")[#bank.bank_name]],
)

#v(2em)

// Calculate totals
#let calculate_totals() = {
  let total_net = 0.0
  let total_vat = 0.0

  for item in items {
    let net_worth = item.quantity * item.price_net
    total_net = total_net + net_worth
    let vat_amount = net_worth * item.vat_rate
    total_vat = total_vat + vat_amount
  }

  (net: total_net, vat: total_vat, gross: total_net + total_vat)
}

#let totals = calculate_totals()

// Main invoice table
#table(
  columns: (auto, 3fr, auto, auto, auto, auto, auto),
  align: left,
  stroke: 1pt,

  // Header row
  [№ \ #text(size: 8pt)[(lp.)]],
  [Name of service \ #text(size: 8pt)[(towar / usługa)]],
  [Qty \ #text(size: 8pt)[(ilość)]],
  [Unit price \ #text(size: 8pt)[(cena netto)]],
  [Net worth \ #text(size: 8pt)[(wartość netto)]],
  [VAT],
  [Gross worth \ #text(size: 8pt)[(wartość brutto)]],

  // Items
  ..for (idx, item) in items.enumerate() {
    let net_worth = item.quantity * item.price_net
    let gross_worth = net_worth * (1 + item.vat_rate)

    let vat_display_with_footnote = if item.vat_rate == 0 {
      if items.slice(0, idx).all(i => i.vat_rate != 0) {
        [
          N/A
          #super[#footnote[
            Reverse charge: the buyer is the VAT taxpayer
            (odwrotne obciążenie: nabywca jest płatnikiem VAT).
          ]<reverse-charge>] \
          #text(size: 8pt)[(NP)]
        ]
      } else {
        [N/A #super[#ref(<reverse-charge>)] \ #text(size: 8pt)[(NP)]]
      }
    } else {
      str(int(item.vat_rate * 100)) + "%"
    }

    let secondary_charge = if "secondary_charge" in item {
      item.secondary_charge
    } else {
      false
    }

    let is_first_secondary = items
      .slice(0, idx)
      .all(it => {
        let sc = if "secondary_charge" in it {
          it.secondary_charge
        } else {
          false
        }
        not sc
      })

    let name_with_footnote = if secondary_charge {
      if is_first_secondary {
        [
          #item.name
          #super[#footnote[
            Reimbursement of costs essential for service delivery, as per the
            agreement (pokrycie kosztów niezbędnych do realizacji usługi
            kompleksowej, zgodnie z umową).
          ]<secondary-charge>] \
          #text(size: 8pt)[(#item.name_pl)]
        ]
      } else {
        [
          #item.name
          #super[#ref(<secondary-charge>)] \
          #text(size: 8pt)[(#item.name_pl)]
        ]
      }
    } else {
      [#item.name \ #text(size: 8pt)[(#item.name_pl)]]
    }

    (
      str(idx + 1) + ".",
      name_with_footnote,
      str(item.quantity),
      [
        #format_usd(item.price_net) \
        #text(size: 8pt)[#format_pln(item.price_net * exchange_rate)]
      ],
      [
        #format_usd(net_worth) \
        #text(size: 8pt)[#format_pln(net_worth * exchange_rate)]
      ],
      vat_display_with_footnote,
      [
        #format_usd(gross_worth) \
        #text(size: 8pt)[#format_pln(gross_worth * exchange_rate)]
      ],
    )
  },
)

#v(1em)

#grid(
  columns: (auto, 1fr),
  gutter: 1em,
  row-gutter: 0.25em,
  [
    #strong[Total to pay:] \
    #text(size: 8pt)[(do zapłaty)]
  ],
  [
    #strong[#format_usd(totals.gross)] \
    #text(size: 8pt)[(#format_pln(totals.gross * exchange_rate))]
  ],
)

#v(1em)

#align(left)[
  Exchange rate of (wg kursu z dnia)
  #text[#exchange_date.display("[year]-[month]-[day]"):]
  #strong[#str(exchange_rate) PLN]
  #footnote[
    Source: NBP Exchange rates archive – table A
    (źródło: NBP Archiwum kursów średnich – tabela A).
  ]
]

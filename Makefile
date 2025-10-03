.PHONY: all fetch clean

all: invoice.pdf

invoice-data.toml:
	@if [ ! -f invoice-data.toml ]; then \
		echo "Creating invoice-data.toml from template..."; \
		cp invoice-data.toml.tmpl invoice-data.toml; \
		echo "Please edit invoice-data.toml with your actual data"; \
		exit 1; \
	fi

invoice.pdf: invoice-data.toml invoice.typ
	python3 fetch-exchange-rate.py
	typst compile invoice.typ

fetch:
	python3 fetch-exchange-rate.py

clean:
	rm -f invoice.pdf invoice.png

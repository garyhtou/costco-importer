# Costco Importer

The primary goal is to convert Costco's In-Warehouse receipts from `costco.com`
into a format that can be easily imported into Google Sheets.

- Compute tax at a per item level. Many receipts lump all the tax together—it's
  much easier to calculate it that way—but, I do need to know the "final" price
  per item and thus need to compute the tax per item.

- Costco handles discounts is a very odd way. Discounts on items are an entirely
  separate line item that needs to be manually associated with the purchased
  item. One goal for this project is to automatically associate discounts and
  compute the total price of each item (after discount and tax).

- Separate items with multiple units/quantities into separate line items. For
  example, if I buy 3 boxes of cereal, I want to see 3 line items for that
  cereal.

## Price Adjustments

Costco allows for price adjustments within 30 days of purchase. The
[`price_adjustment.rb`](price_adjustment.rb) script will check for new discounts
on items purchased within the last 30 days. It pulls old receipts from the
[`/data`](/data) folder.

## Usage

See [`/data/README.md`](data/README.md) for details.

- To import, run `ruby import.rb`
- To check for price adjustments, run `ruby price_adjustment.rb`

## Instacart API

Costco's same-day site is powered by Instacart. I've created a simple wrapper
[`Instacart`](/instacart.rb) around their GraphQL API for searching and
retrieving items.

The wrapper automatically creates a guest user in order to authenticate with
the API.

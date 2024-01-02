require "json"

class Importer
  def initialize(filepath)
    @filepath = filepath
  end

  def parse
    datetime = receipt_json.dig("transactionDateTime")

    receipt = Receipt.new(warehouse:, member:, datetime:)
    receipt_json.dig("itemArray").each do |item|
      if item_json_is_discount?(item)
        receipt << item_json_to_discount(item)
      else
        receipt << item_json_to_item(item)
      end
    end

    verify receipt

    receipt
  end

  private

  def verify(receipt)
    receipt.validate!

    # Compare against computed values in receipt JSON
    raise "Receipt total mismatch" if receipt.total != receipt_json.dig("total")
    raise "Receipt subtotal mismatch" if receipt.subtotal != receipt_json.dig("subTotal")
    raise "Receipt tax mismatch" if receipt.tax != receipt_json.dig("taxes")
    raise "Receipt total item count mismatch" if receipt.total_items != receipt_json.dig("totalItemCount")
    raise "Receipt unique item & discount count mismatch" if receipt.items.count + receipt.discounts.count != receipt_json.dig("itemArray").count
    raise "Receipt datetime mismatch" if receipt.datetime.strftime('%Y-%m-%dT%H:%M:%S') != receipt_json.dig("transactionDateTime")

    raise "Warehouse name mismatch" if receipt.warehouse.name != receipt_json.dig("warehouseName")
    raise "Warehouse number mismatch" if receipt.warehouse.number != receipt_json.dig("warehouseNumber")

    raise "Membership number mismatch" if receipt.member.membership_number != receipt_json.dig("membershipNumber")
  end

  def warehouse
    Warehouse.new(name: receipt_json.dig("warehouseName"), number: receipt_json.dig("warehouseNumber"))
  end

  def member
    Member.new(membership_number: receipt_json.dig("membershipNumber"))
  end

  def discount_json(item_json)
    description = item_json.dig("itemDescription01")
    associated_item_number = item_json.dig("frenchItemDescription1") # idk why it's stored here
    unit = item_json.dig("unit")
    amount = item_json.dig("amount")

    starts_with_slash = [description, associated_item_number].all? { |t| t.starts_with? "/" }
    parsed_associated_item_id = associated_item_number&.match(/\/(\d+)/)&.[](1)&.to_i

    is_discount = unit.negative? && amount.negative? && starts_with_slash && !parsed_associated_item_id.nil?
    return unless is_discount

    {
      associated_item_number: parsed_associated_item_id
    }
  end

  def item_json_is_discount?(item_json)
    discount_json(item_json).present?
  end

  def item_json_to_item(item_json)
    price_cents = (item_json.dig("amount") * 100).round # it should be a whole float

    Item.new(
      number: item_json.dig("itemNumber"),
      name: item_json.dig("itemDescription01"),
      price_cents:,
      description: item_json.dig("itemDescription02"),
      unit: item_json.dig("unit"),
      tax_flag: item_json.dig("taxFlag")
    )
  end

  def item_json_to_discount(item_json)
    discount = discount_json(item_json)
    amount_cents = (item_json.dig("amount") * 100).round # it should be a whole float

    Discount.new(
      associated_item_number: discount[:associated_item_number],
      unit: item_json.dig("unit").abs,
      amount_cents:
    )
  end

  def receipt_json
    # Assume there's only one receipt in the array
    json.dig("data", "receipts").first
  end

  def json
    @json ||= JSON.parse(file)
  end

  def file
    @file ||= File.read(@filepath)
  end

end


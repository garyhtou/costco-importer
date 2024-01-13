require "json"

class Importer
  def initialize(filepath)
    @filepath = filepath
  end

  def parse
    datetime = receipt_json.dig("transactionDateTime")

    receipt = Receipt.new(warehouse:, member:, datetime:)
    receipt_json.dig("itemArray").each do |item|
      if item_json_is_modifier?(item)
        receipt << item_json_to_modifier(item)
      else
        receipt << item_json_to_item(item)
      end
    end

    verify receipt

    receipt
  end

  private

  def warehouse
    Warehouse.new(name: receipt_json.dig("warehouseName"), number: receipt_json.dig("warehouseNumber"))
  end

  def member
    Member.new(membership_number: receipt_json.dig("membershipNumber"))
  end

  def modifier_json(item_json)
    associated_item_number = item_json.dig("frenchItemDescription1") # idk why it's stored here

    starts_with_slash = associated_item_number&.starts_with? "/"
    parsed_associated_item_id = associated_item_number&.match(/\/(\d+)/)&.[](1)&.to_i
    return unless starts_with_slash && parsed_associated_item_id.present?

    {
      associated_item_number: parsed_associated_item_id
    }
  end

  def item_json_is_modifier?(item_json)
    # Either discount or additional tax
    modifier_json(item_json).present?
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

  def item_json_to_modifier(item_json)
    modifier = modifier_json(item_json)
    amount_cents = (item_json.dig("amount") * 100).round # it should be a whole float

    Modifier.new(
      number: item_json.dig("itemNumber"),
      associated_item_number: modifier[:associated_item_number],
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

  def verify(receipt)
    receipt.validate!

    # Compare against computed values in receipt JSON
    warn "Receipt total mismatch" if receipt.total != receipt_json.dig("total")
    warn "Receipt subtotal mismatch" if receipt.subtotal != receipt_json.dig("subTotal")
    warn "Receipt tax mismatch" if receipt.tax != receipt_json.dig("taxes")
    warn "Receipt total item count mismatch" if receipt.total_items != receipt_json.dig("totalItemCount")
    warn "Receipt unique item & modifier count mismatch" if receipt.items.count + receipt.modifiers.count != receipt_json.dig("itemArray").count
    warn "Receipt datetime mismatch" if receipt.datetime.strftime('%Y-%m-%dT%H:%M:%S') != receipt_json.dig("transactionDateTime")

    warn "Warehouse name mismatch" if receipt.warehouse.name != receipt_json.dig("warehouseName")
    warn "Warehouse number mismatch" if receipt.warehouse.number != receipt_json.dig("warehouseNumber")

    warn "Membership number mismatch" if receipt.member.membership_number != receipt_json.dig("membershipNumber")
  end

end


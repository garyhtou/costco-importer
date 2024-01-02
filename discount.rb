class Discount
  attr_reader :associated_item_number
  attr_reader :unit, :amount_cents
  attr_accessor :item

  def initialize(associated_item_number:, unit:, amount_cents:)
    @associated_item_number = associated_item_number
    @unit = unit
    @amount_cents = amount_cents

    @item = nil
  end
end
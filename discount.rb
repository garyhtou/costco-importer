class Discount
  attr_reader :number, :associated_item_number
  attr_reader :unit, :amount_cents
  attr_accessor :item

  def initialize(number:, associated_item_number:, unit:, amount_cents:)
    @number = number
    @associated_item_number = associated_item_number
    @unit = unit
    @amount_cents = amount_cents

    @item = nil
  end
end
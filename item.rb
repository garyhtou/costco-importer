class Item

  attr_reader :number, :name, :description
  attr_reader :price_cents, :unit, :tax_flag
  attr_reader :discounts
  attr_accessor :receipt

  def initialize(number:, name:, price_cents:, description:, unit:, tax_flag:)
    @number = number.to_i
    @name = name
    @price_cents = price_cents # Price before discounts and tax
    @description = description
    @unit = unit
    @tax_flag = tax_flag

    @discounts = [] # I've only seen one discount per item, but I'm not sure if that's always the case; thus the array
    @receipt = nil
  end

  def pretty_name
    product&.name || name.titleize
  end

  def image_url
    product&.image_url
  end

  def product
    product = Product.new(@number)
    return nil if product.not_found?

    product
  end

  # Price after discounts and tax
  def total_price_cents
    discounted_price_cents + tax_cents
  end

  # Tax amount cents
  def tax_cents
    (discounted_price_cents * tax_rate).round
  end

  # Price after discounts, before tax
  def discounted_price_cents
    @price_cents + total_discount_cents
  end

  # Total discount for this item (negative number)
  def total_discount_cents
    @discounts.reduce(0) do |sum, discount|
      sum + discount.amount_cents * discount.unit
    end
  end

  %w[total_price discounted_price price tax total_discount].each do |method_name|
    define_method method_name do
      send("#{method_name}_cents") / 100.0
    end

    # Define methods for Unit
    define_method "unit_#{method_name}_cents" do
      # This doesn't get rounded because calculating per-unit price can result
      # in partial cents; mainly when discounts are applied (buy 1, get 1 free).
      # Buy 1, get 1 free appears at 2 units, 1 discount. (e.g. (9.99 + 9.99 - 9.99) / 2 = 4.995)
      send("#{method_name}_cents") / @unit.to_f
    end
    define_method "unit_#{method_name}" do
      send("unit_#{method_name}_cents") / 100.0
    end
  end

  def apply_discount(discount)
    raise ArgumentError, "Discount can not be applied to this item" if discount.associated_item_number != @number

    discount.item = self
    @discounts << discount
  end

  def tax_calculator
    raise ArgumentError, "Item must be associated with a receipt/warehouse to create TaxCalculator" unless @receipt.present?

    TaxCalculator.new(warehouse_number: @receipt.warehouse.number, tax_flag: @tax_flag)
  end

  delegate :tax_rate, :taxable?, to: :tax_calculator

end

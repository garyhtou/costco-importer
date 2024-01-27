class Item

  attr_reader :number, :name, :description
  attr_reader :price_cents, :unit, :tax_flag
  attr_reader :modifiers
  attr_accessor :receipt

  def initialize(number:, name:, price_cents:, description:, unit:, tax_flag:)
    @number = number.to_i
    @name = name
    @price_cents = price_cents # Price before modifiers (discounts) and tax
    @description = description
    @unit = unit
    @tax_flag = tax_flag

    @modifiers = [] # I've only seen one discount per item, but I'm not sure if that's always the case; thus the array
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
    modified_price_cents + tax_cents
  end

  # Tax amount cents
  def tax_cents
    tax_calculator.calculate_tax_cents(self)
  end

  # Price after discounts/fees/additional taxes, before tax
  def modified_price_cents
    @price_cents + total_modified_cents
  end

  # Total modified for this item (negative number)
  def total_modified_cents
    @modifiers.sum(&:amount_cents)
  end

  # Total modified, only including discounts (excluding fees/additional taxes)
  def total_discounted_cents
    @modifiers.filter do |modifier|
      modifier.amount_cents.negative?
    end.sum(&:amount_cents)
  end

  %w[total_price modified_price price tax total_modified total_discounted].each do |method_name|
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

  def apply_modifier(modifier)
    warn ArgumentError, "Modifier can not be applied to this item" if modifier.associated_item_number != @number

    modifier.item = self
    @modifiers << modifier
  end

  def tax_calculator
    warn ArgumentError, "Item must be associated with a receipt/warehouse to create TaxCalculator" unless @receipt.present?

    TaxCalculator.new(warehouse_number: @receipt.warehouse.number, tax_flag: @tax_flag)
  end

  delegate :tax_rate, :taxable?, to: :tax_calculator

end

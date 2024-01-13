class Receipt
  attr_reader :warehouse, :member
  attr_reader :datetime
  attr_reader :items, :discounts, :unapplied_discounts

  def initialize(warehouse:, member:, datetime:)
    @warehouse = warehouse
    @member = member
    @datetime = datetime.to_datetime

    @items = []
    @discounts = []
    @unapplied_discounts = []
  end

  def total_cents
    @items.sum(&:total_price_cents)
  end

  def subtotal_cents
    @items.sum(&:discounted_price_cents)
  end

  def tax_cents
    @items.sum(&:tax_cents)
  end

  %w[total subtotal tax].each do |method_name|
    define_method method_name do
      send("#{method_name}_cents") / 100.0
    end
  end

  def total_items
    @items.sum(&:unit)
  end

  def <<(item)
    if item.is_a? Discount
      @unapplied_discounts << item
    else
      @items << item
    end

    # Associate the item with this receipt
    if item.respond_to? :receipt=
      item.receipt = self
    end

    apply_discounts
  end

  def apply_discounts
    @unapplied_discounts = @unapplied_discounts.filter_map do |discount|
      associated_item = @items.find { |i| i.number == discount.associated_item_number }
      if associated_item
        associated_item.apply_discount(discount)
        @discounts << discount
        next nil
      end

      discount # keep this discount. it remains unapplied
    end
  end

  def unapplied_discounts?
    @unapplied_discounts.any?
  end

  def validate!
    raise "Receipt has unapplied discounts" if unapplied_discounts?
    raise "Receipt unit price mismatch" if @items.sum(&:price) != @items.sum { |i| i.unit * i.unit_price }
    raise "Receipt unit price total mismatch" if total != @items.sum { |i| i.unit * i.unit_total_price }
  end

  def self.parse(filepath)
    Importer.new(filepath).parse
  end
end
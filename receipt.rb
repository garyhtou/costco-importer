class Receipt
  attr_reader :warehouse, :member
  attr_reader :datetime
  attr_reader :items, :modifiers, :unapplied_modifiers

  def initialize(warehouse:, member:, datetime:)
    @warehouse = warehouse
    @member = member
    @datetime = datetime.to_datetime

    @items = []
    @modifiers = []
    @unapplied_modifiers = []
  end

  def total_cents
    @items.sum(&:total_price_cents)
  end

  def subtotal_cents
    @items.sum(&:modified_price_cents)
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
    if item.is_a? Modifier
      @unapplied_modifiers << item
    else
      @items << item
    end

    # Associate the item with this receipt
    if item.respond_to? :receipt=
      item.receipt = self
    end

    apply_modifiers
  end

  def apply_modifiers
    @unapplied_modifiers = @unapplied_modifiers.filter_map do |modifier|
      associated_item = @items.find { |i| i.number == modifier.associated_item_number }
      if associated_item
        associated_item.apply_modifier(modifier)
        @modifiers << modifier
        next nil
      end

      modifier # keep this modifier. it remains unapplied
    end
  end

  def unapplied_modifiers?
    @unapplied_modifiers.any?
  end

  def validate!
    warn "Receipt has unapplied modifiers" if unapplied_modifiers?
    warn "Receipt unit price cents mismatch" if @items.sum(&:price_cents) != @items.sum { |i| i.unit * i.unit_price_cents }
    warn "Receipt unit price total cents mismatch" if total_cents != @items.sum { |i| i.unit * i.unit_total_price_cents }
  end

  def self.parse(filepath)
    Importer.new(filepath).parse
  end
end
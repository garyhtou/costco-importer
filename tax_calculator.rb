class TaxCalculator
  def initialize(warehouse_number:, tax_flag:, date:)
    @warehouse_number = warehouse_number
    @tax_flag = tax_flag
    @date = date
  end

  TAX_FLAGS = {
    "Y": {
      rate: :sales_tax_rate,
      on: :modified_price_cents
    },
    "4": {
      rate: :spirits_tax_rate,
      on: :price_cents
    }
  }

  def calculate_tax_cents(item)
    return 0 unless taxable?

    taxable_amount_method = TAX_FLAGS[@tax_flag.to_sym][:on]
    warn ArgumentError, "Unknown tax flag \"#{@tax_flag}\"" if taxable_amount_method.nil?

    (item.send(taxable_amount_method) * tax_rate).round
  end

  def tax_rate
    return 0 unless taxable?

    rate_method = TAX_FLAGS[@tax_flag.to_sym][:rate]
    warn ArgumentError, "Unknown tax flag \"#{@tax_flag}\". I'm not sure how to calculate tax for this" if rate_method.nil?

    send rate_method
  end

  def sales_tax_rate
    return 0 unless taxable?

    case @warehouse_number
    when 1 # Seattle
      @date.before?(Date.new(2024, 1, 1)) ? 0.1025 : 0.1035
    when 6, 95 # Tukwila, Tacoma
      0.101
    when 1190 # Lynnwood
      0.106
    else
      warn ArgumentError, "Unknown warehouse number \"#{@warehouse_number}\". I'm not sure how to calculate sales tax for this location"
    end
  end

  def spirits_tax_rate
    return 0 unless taxable?

    case @warehouse_number
    when 1 # Seattle
      0.205
    else
      warn ArgumentError, "Unknown warehouse number \"#{@warehouse_number}\". I'm not sure how to calculate spirits tax for this location"
    end
  end

  def taxable?
    !@tax_flag.in? ["N", nil]
  end
end


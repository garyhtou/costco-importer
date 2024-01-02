class TaxCalculator
  def initialize(warehouse_number:, tax_flag:)
    @warehouse_number = warehouse_number
    @tax_flag = tax_flag
  end

  def tax_rate
    return 0 unless taxable?

    case @tax_flag
    when "Y"
      sales_tax_rate
    else
      # There may be other tax flags
      raise ArgumentError, "Unknown tax flag. I'm not sure how to calculate tax for this"
    end
  end

  def sales_tax_rate
    return 0 unless taxable?

    case @warehouse_number
    when 1 # Seattle
      0.1025
    when 6, 95, 1190 # Tukwila, Tacoma, Lynnwood
      0.101
    else
      raise ArgumentError, "Unknown warehouse. I'm not sure how to calculate tax for this location"
    end
  end

  def taxable?
    @tax_flag != "N"
  end
end


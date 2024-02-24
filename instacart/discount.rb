class Instacart
  class Discount
    attr_reader :label, :qualifying_quantity, :amount_cents

    def initialize(label)
      @label = label
      raise ArgumentError, "Label cannot be blank" if @label.blank?

      @qualifying_quantity = nil
      @amount_cents = nil

      parse_label
    end

    def self.from_label(label)
      discount = new(label)
      return discount if discount.valid?
    end

    def valid?
      @amount_cents.present?
    end

    def to_h
      {
        label: @label,
        qualifying_quantity: @qualifying_quantity,
        amount_cents: @amount_cents,
      }
    end

    # These regexes handle parsing the label. The order is important as they are
    # evaluated from top to bottom until a match is found. They regexes may
    # contain the following named captures:
    #   - qualifying_quantity
    #   - amount
    #   - quantity_limit
    PARSER_REGEXES = [
      /Buy.*(?<qualifying_quantity>\d+),.*\$(?<amount>\d+(\.\d+)?)/i,
      # - Buy 1, get $2.60 off
      # - Buy any 2, save $0.50

      /\$(?<amount>\d+(\.\d+)?) off(?:.*limit\s+(?<quantity_limit>\d+))?/i
      # - $2 off
      # - $2.60 off; limit 10

      # Other formats i'm currently not handling:
      # - Spend $28, save $5
    ]

    private

    def parse_label
      PARSER_REGEXES.each do |regex|
        next unless (captures = regex.match(@label)&.named_captures)
        next unless captures["amount"] # Amount is required

        @amount_cents = (captures["amount"].to_f * 100).round

        # Optional captures
        @qualifying_quantity = captures["qualifying_quantity"]&.to_i || 1
        @quantity_limit = captures["quantity_limit"]&.to_i
        return
      end
    end
  end
end

require "csv"

module Serializers
  class CSV
    def initialize(receipt)
      @receipt = receipt
    end

    def serialize
      ::CSV.generate do |csv|
        csv << member_header
        @receipt.items.each do |item|
          # Give each unit/quantity its own row
          item.unit.times do
            csv << item_row(item)
          end
        end
      end
    end

    def item_row(item)
      [
        item.number,
        item.name,
        "", # pretty name
        item.price,
        # item.tax_flag,
        item.total_price
      ]
    end

    def member_header
      ["Member #{@receipt.member.membership_number}"]
    end
  end

end
require "csv"

module Serializers
  class CSV
    def initialize(receipt)
      @receipt = receipt
    end

    def serialize
      ::CSV.generate do |csv|
        csv << header
        @receipt.items.each do |item|
          # Give each unit/quantity its own row
          item.unit.times do
            csv << item_unit_row(item)
          end
        end
      end
    end

    def item_unit_row(item)
      [
        image(item.image_url),
        item.number,
        item.pretty_name,
        item.unit_price,
        item.unit_total_price
      ]
    end

    def image(url)
      url ||= "https://static.thenounproject.com/png/3674270-200.png" # Default image

      "=image(\"#{url}\")"
    end

    def header
      ["Member #{@receipt.member.membership_number}", nil, nil, "Price", "Final Price"]
    end
  end

end
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
            csv << item_row(item)
          end
        end
      end
    end

    def item_row(item)
      [
        item.number,
        item.pretty_name || item.name,
        image(item.image_url),
        item.total_price
      ]
    end

    def image(url)
      url ||= "https://static.thenounproject.com/png/3674270-200.png" # Default image

      "=image(\"#{url}\")"
    end

    def header
      ["Member #{@receipt.member.membership_number}", nil, nil, "Price + Tax"]
    end
  end

end
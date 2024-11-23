require_relative "client"
require_relative "discount"

module Instacart
  class Item < Client
    def initialize(id)
      @id = id
    end

    def item
      json = raw_item.dig("data", "items").select do |j|
        j["id"] == @id
      end.first
      return nil unless json

      warn "Price not found for #{@id}" if json.dig("price").nil?

      discount = Instacart::Discount.from_label(json.dig("price", "viewSection", "badge", "offerLabelString"), id: @id)&.to_h

      price_cents = price_to_cents(json.dig("price", "viewSection", "priceString"))
      full_price_cents = price_to_cents(json.dig("price", "viewSection", "fullPriceString"))
      full_price_cents ||= price_cents # `fullPriceString` is only present when item is discounted

      {
        id: json["id"], # "items_359-2343754"
        product_id: json["productId"], # "2343754"
        name: json["name"], # "Organic Crimini Mushrooms, 24 oz"
        size: json["size"], # "each"
        brand_name: json["brandName"], # "monterey mushrooms"
        dietary: json.dig("dietary", "mlDietaryAttributes"), # "organic"
        image_url: json.dig("viewSection", "itemImage", "url"), # "https://d2lnr5mha7bycj.cloudfront.net/product-image/file/large_56cecdbd-92b0-40ec-88d7-02f4132d9a9e.jpeg"
        retailer_reference_code: json.dig("viewSection", "retailerReferenceCodeString"), # "121288"
        product_category_name: json.dig("viewSection", "trackingProperties", "product_category_name"), # "Baby Bella Mushrooms"

        price_cents:,
        full_price_cents:,
        discount:,
        site_url: "https://sameday.costco.com/store/costco/products/#{json["productId"]}"
      }
    end

    private

    def price_to_cents(string)
      return nil if string.blank?

      (string.remove("$").to_f * 100).round
    end

    def raw_item
      CACHE.fetch("raw_item:#{@id}") do
        self.class.get item_url
      end
    end

    def item_url
      # `shopId` and `zoneId` (and Cookie auth) are required for retrieving the
      # price. Postal code is required for getting the price.
      %Q(https://sameday.costco.com/graphql?operationName=Items&variables=%7B%22ids%22%3A%5B%22#{@id}%22%5D%2C%22shopId%22%3A%22#{SHOP_ID}%22%2C%22zoneId%22%3A%22#{ZONE_ID}%22%2C%22postalCode%22%3A%22#{POSTAL_CODE}%22%7D&extensions=%7B%22persistedQuery%22:%7B%22version%22:1,%22sha256Hash%22:%220569d5997f69659900bde2d8b65943a3968b7d4a52e7851d564f7f35d4596f85%22%7D%7D)
    end
  end
end

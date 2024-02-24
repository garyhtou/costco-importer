require "httparty"
require "singleton"

# Costco's Same Day delivery site uses Instacart
#
# This class is a wrapper around Instacart's private GraphQL API. It requires
# authentication; thus, the `data/cookies.txt` file is required.
class Instacart
  include HTTParty
  include Singleton

  def product(costco_number)
    costco_number = costco_number.to_s
    search(costco_number).select do |item|
      item[:retailer_reference_code] == costco_number
    end.first
  end

  def price(instacart_id:)
    json = price_raw instacart_id

    result = json.dig("data", "itemPrices").filter do |j|
      j.dig("id") == instacart_id
    end&.first
    return nil unless result

    price_cents = (result.dig("viewSection", "priceString").remove("$").to_f * 100).round

    discount = result.dig("viewSection", "badge", "offerLabelString")&.then do |label|
      # Example of labels:
      # - Buy 1, get $2.60 off
      # - Buy any 2, save $0.50
      # - $2 off
      # - $2.60 off; limit 10
      # - Spend $28, save $5 (I'm not going to handle this case)

      /Buy.*(?<quantity>\d+),.*\$(?<amount>\d+(\.\d+)?)/i =~ label
      if quantity.nil?
        /\$(?<amount>\d+(\.\d+)?) off/i =~ label
        quantity = 1 if amount.present?
      end

      unless quantity && amount
        warn "Found unknown discount for #{instacart_id}: #{label}"
        next nil
      end

      {
        qualifying_quantity: quantity.to_i,
        amount_cents: (amount.to_f * 100).round,
        label:,
      }
    end

    {
      price_cents:,
      discount:,
    }
  end

  private

  def search(query)
    json = search_raw query

    results = json.dig("data", "searchResultsPlacements", "placements").filter do |j|
      j.dig("content", "items")
    end.first&.dig("content", "items")
    return [] unless results

    results.map do |product|
      self.class.send(:json_product_to_product, product)
    end
  end

  def self.json_product_to_product(json_item)
    {
      id: json_item.dig("id"),
      name: json_item.dig("name"),
      size: json_item.dig("size"),
      product_id: json_item.dig("productId"),
      brand_name: json_item.dig("brandName"),
      image_url: json_item.dig("viewSection", "itemImage", "url"),
      retailer_reference_code: json_item.dig("viewSection", "retailerReferenceCodeString"),
    }
  end

  PRODUCT_KEYS = Instacart.json_product_to_product({}).keys
  private_class_method :json_product_to_product

  def search_raw(query)
    @search ||= {} # Cache store

    @search[query] ||= self.class.get(search_url(query), headers: { cookie: cookies })
  end

  def search_url(query)
    # The search page (https://sameday.costco.com/store/costco/s?k=my%20query)
    # hits this GraphQL endpoint to load the results
    "https://sameday.costco.com/graphql?operationName=SearchResultsPlacements&variables={\"filters\":[],\"action\":null,\"query\":\"#{query}\",\"pageViewId\":\"\",\"retailerInventorySessionToken\":\"\",\"elevatedProductId\":null,\"searchSource\":\"search\",\"disableReformulation\":false,\"disableLlm\":false,\"forceInspiration\":false,\"orderBy\":\"default\",\"clusterId\":null,\"includeDebugInfo\":false,\"clusteringStrategy\":null,\"contentManagementSearchParams\":{\"itemGridColumnCount\":4,\"aisleGridVericalCarouselCount\":2,\"aisleGridVericalCarouselItemGridVisibleColumnCount\":2,\"aisleGridVericalCarouselItemGridCount\":1},\"shopId\":\"1287\"}&extensions={\"persistedQuery\":{\"version\":1,\"sha256Hash\":\"02ef9d3dbe4351b81074b95a56a4c82d73c1bf40d82da89c873e7befecd665b3\"}}"
  end

  def price_raw(query)
    @price ||= {} # Cache store

    @price[query] ||= self.class.get(price_url(query), headers: { cookie: cookies })
  end

  def price_url(instacart_id)
    # N.B. These prices are Instacart's prices, not Costco warehouse prices.
    # Online prices will be more expensive, however, they are useful for
    # determining if there is a sale. From my observation, the sales online
    # are identical to the warehouse. (ex. $2 off online, $2 off in warehouse)

    # This URL contains some hardcode params such as postal code.
    "https://sameday.costco.com/graphql?operationName=ItemPricesQuery&variables={\"ids\":[\"#{instacart_id}\"],\"shopId\":\"1287\",\"zoneId\":\"33\",\"postalCode\":\"98105\"}&extensions={\"persistedQuery\":{\"version\":1,\"sha256Hash\":\"af2baab4d94cf2477bacf7a04abe0736e624835c832cfbabbcdf2f68b511c3c7\"}}"
  end

  def cookies
    File.open("data/cookies.txt") do |f|
      return f.read.chomp!
    end
  end
end

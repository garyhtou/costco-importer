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

  def cookies
    File.open("data/cookies.txt") do |f|
      return f.read.chomp!
    end
  end
end

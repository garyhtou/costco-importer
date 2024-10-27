require_relative "client"

module Instacart
  class Search < Client

    def initialize(query)
      @query = query
    end

    def item_ids
      results = raw_search.dig("data", "searchResultsPlacements", "placements").map do |j|
        j.dig("content", "itemIds")
      end.compact.first

      return [] unless results

      results
    end

    private

    def raw_search
      CACHE.fetch("raw_search:#{@query}") do
        self.class.get search_url
      end
    end

    def search_url
      %Q(https://sameday.costco.com/graphql?operationName=SearchResultsPlacements&variables=%7B%22filters%22%3A%5B%5D%2C%22action%22%3Anull%2C%22query%22%3A%22#{@query}%22%2C%22pageViewId%22%3A%22%22%2C%22retailerInventorySessionToken%22%3A%22%22%2C%22elevatedProductId%22%3Anull%2C%22searchSource%22%3A%22search%22%2C%22disableReformulation%22%3Afalse%2C%22disableLlm%22%3Afalse%2C%22forceInspiration%22%3Afalse%2C%22orderBy%22%3A%22bestMatch%22%2C%22clusterId%22%3Anull%2C%22includeDebugInfo%22%3Afalse%2C%22clusteringStrategy%22%3Anull%2C%22contentManagementSearchParams%22%3A%7B%22itemGridColumnCount%22%3A2%7D%2C%22shopId%22%3A%22#{Instacart::SHOP_ID}%22%2C%22postalCode%22%3A%22%22%2C%22zoneId%22%3A%22%22%2C%22first%22%3A4%7D&extensions=%7B%22persistedQuery%22%3A%7B%22version%22%3A1%2C%22sha256Hash%22%3A%22520e6f54031039eba324b8d5c714df73fb82b66bb00ace56c3a3c2a87419bc60%22%7D%7D)
    end
  end
end

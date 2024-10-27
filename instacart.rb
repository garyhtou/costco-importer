require "httparty"
require "singleton"

require_relative "instacart/search"
require_relative "instacart/item"

# Costco's Same Day delivery site uses Instacart.
# This module is a wrapper around Instacart's GraphQL API.
module Instacart
  SHOP_ID = 1287.to_s # Costco Seattle (4th St.)
  ZONE_ID = 33.to_s
end

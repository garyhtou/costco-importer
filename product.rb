require_relative "instacart"
require "json"

class Product
  def initialize(number)
    @number = number.to_s
  end

  def not_found?
    instacart_item_hash.nil?
  end

  def method_missing(...)
    if instacart_item.respond_to?(...)
      instacart_item.public_send(...)
    else
      super
    end
  end

  def respond_to_missing?(...)
    instacart_item.respond_to?(...) || super
  end

  private

  def instacart_item
    # The OpenStruct makes the hash accessible via method calls; used by delegate
    # JSON is used as a hack to recursively convert the hash to an OpenStruct
    @instacart_product ||= JSON.parse(instacart_item_hash.to_json, object_class: OpenStruct)
  end

  def instacart_item_hash
    @instacart_product_hash ||=
      begin
        ids = Instacart::Search.new(@number).item_ids

        ids.find do |id|
          item = Instacart::Item.new(id).item
          next if item.nil?

          break item if item[:retailer_reference_code] == @number
        end
      end
  end

end

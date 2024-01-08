class Product
  delegate :name, :size, :brand_name, :image_url, to: :instacart_product

  def initialize(number)
    @number = number
  end

  def not_found?
    instacart_product_hash.nil?
  end

  private

  def instacart_product
    # The OpenStruct makes the hash accessible via method calls; used by delegate
    @instacart_product ||= OpenStruct.new(instacart_product_hash)
  end

  def instacart_product_hash
    @instacart_product_hash ||= Instacart.instance.product(@number)
  end

end

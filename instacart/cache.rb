module Instacart
  class Cache
    def initialize
      @cache = {}
    end

    def fetch(key)
      return @cache[key] if @cache.key?(key)

      @cache[key] = yield
    end

  end
end
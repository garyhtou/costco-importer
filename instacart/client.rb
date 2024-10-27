require_relative "cache"

module Instacart
  class Client
    include HTTParty
    CACHE = Instacart::Cache.new

    def self.generate_auth_token
      # Create new guest user
      res = HTTParty.post("https://sameday.costco.com/graphql", body: {
        "operationName": "HomepagePbiCreateGuestUserWithPostalCodeMutation",
        "variables": {
          "postalCode": "" # Not required
        },
        "extensions": {
          "persistedQuery": {
            "version": 1,
            "sha256Hash": "60933aab54d6b3f2add1fec396506dae6ef9b6a1891effbdaf39db129e787446"
          }
        }
      }.to_json, headers: { 'Content-Type' => 'application/json' })

      token = res.dig("data", "createGuestUser", "token")
      raise "Failed to generate Instacart auth token" unless token

      token
    end

    cookies({ "__Host-instacart_sid": generate_auth_token })

  end

end
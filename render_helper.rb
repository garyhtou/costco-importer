def currency(amount = nil, cents: nil)
  amount ||= cents / 100.0
  raise ArgumentError, "Provide either amount or cents" if amount.nil?

  format("$%.2f", amount)
end

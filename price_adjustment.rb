require_relative "receipt"

# The purpose of this script is to check for possible price adjustments.
# Costco allows for price adjustments within 30 days of purchase.

receipt_paths = Dir.glob("data/receipt*.json")
receipt_paths.each do |path|
  receipt = Receipt.parse path
  next if receipt.datetime.before? 30.days.ago

  puts "Checking #{path}"

  receipt.items.each do |item|
    discount = item.product&.current_discount
    next unless discount

    # Check qualification for discount
    next unless discount[:qualifying_quantity] <= item.unit

    receipt_discount = item.unit_total_discounted_cents.abs
    diff = discount[:amount_cents] - receipt_discount
    next if diff <= 0

    puts "\nYou could have saved an additional $#{diff / 100.0} on #{item.pretty_name} (#{item.number})"
    puts "\tReceipt price: $#{item.price}"
    puts "\tReceipt total price: $#{item.total_price}"
    puts "\tReceipt discount: $#{receipt_discount}"
    puts "\tCurrent discount: #{discount[:label]}"
    puts
  end

end

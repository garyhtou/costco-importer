require_relative "receipt"

# The purpose of this script is to check for possible price adjustments.
# Costco allows for price adjustments within 30 days of purchase.

class PriceAdjuster
  def initialize(receipt)
    @receipt = receipt
  end

  def receipt_eligible?
    # Policy is 30 days (i'm adding a 1 day buffer)
    31.days.ago.beginning_of_day.before? @receipt.datetime
  end

  def receipt_ineligible?
    !receipt_eligible?
  end

  def receipt_age
    days = ((Time.now - @receipt.datetime) / 1.day).ceil
    "#{days} days"
  end

  def possible_adjustments
    @possible_adjustments ||=
      begin
        @receipt.items.filter_map do |item|
          discount = item.product&.current_discount
          next unless discount

          # Check qualification for discount
          qualified_count = (item.unit / discount[:qualifying_quantity]).floor
          next if qualified_count.zero?

          receipt_total_discount_cents = item.total_discounted_cents.abs
          total_discount_cents = discount[:amount_cents] * qualified_count
          diff_cents = total_discount_cents - receipt_total_discount_cents
          next if diff_cents <= 0

          # Adjustment hash
          {
            item: item,
            discount: discount,

            discount_qualified_count: qualified_count,
            diff_cents:,
          }
        end
      end
  end
end

def currency(amount = nil, cents: nil)
  raise ArgumentError, "Provide either amount or cents" if amount.nil? && cents.nil?

  amount ||= cents / 100.0
  format("$%.2f", amount)
end

receipt_paths = Dir.glob("data/receipt*.json")
receipt_paths.each do |path|
  puts "\n\nChecking #{path}"

  receipt = Receipt.parse path
  adjuster = PriceAdjuster.new(receipt)

  if adjuster.receipt_ineligible?
    puts "Ineligible: past 30 days (#{adjuster.receipt_age} old)"
    next
  end

  adjuster.possible_adjustments.each do |adjustment|
    item, discount, diff_cents = adjustment.values_at(:item, :discount, :diff_cents)

    puts "\nSave #{currency cents: diff_cents} on #{item.pretty_name} (#{item.number})"
    puts "\tReceipt price:     #{currency item.unit_price} x #{item.unit} = #{currency item.price} (total: #{currency item.total_price})"
    puts "\tReceipt discount:  #{currency item.total_discounted}" +
           begin
             item.total_discounted.zero? ? "" : " (#{currency item.unit_total_discounted}/unit)"
           end
    puts "\tCurrent Discount:  #{discount[:label]}"
  end

  puts "No adjustments" if adjuster.possible_adjustments.none?
end
require "active_support/all"

require_relative "importer"
require_relative "receipt"
require_relative "item"
require_relative "modifier"
require_relative "warehouse"
require_relative "tax_calculator"
require_relative "member"
require_relative "product"
require_relative "instacart"

require_relative "serializers/csv"

require "debug"

receipt = Receipt.parse("data/receipt.json")
csv = Serializers::CSV.new(receipt).serialize

filename = "#{receipt.datetime.strftime('%Y-%m-%d')} Costco.csv"
directory = "output"
filepath = "#{directory}/#{filename}"

FileUtils.mkdir_p(directory) unless File.directory?(directory)
File.open(filepath, "w") do |f|
  f.write(csv)
end

puts "Wrote Receipt CSV to #{filepath}"
puts "You brought #{receipt.total_items} items, totaling to $#{receipt.total}"

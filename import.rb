require_relative "receipt"
require_relative "serializers/csv"
require_relative "render_helper"

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
puts "You brought #{receipt.total_items} items, totaling to #{currency receipt.total}"

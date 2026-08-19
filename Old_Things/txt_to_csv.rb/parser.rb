require 'csv'

ARGV.each do |file_name|
  CSV.open("#{file_name}.csv", "w") do |csv|
    puts "Processing: #{file_name}.."
    File.open(file_name).each do |line|
      begin
        # Sometimes files aren't encoded properly, so we force them!
        line.encode!("utf-8", "utf-8", :invalid => :replace)
        csv << line.split('^').map do |item|
          item.strip!
          item = (item.eql?('~~') || item.eql?('^^')) ? ' ' : item
          item.slice!(0) if item.start_with?('~')
          item.slice!(-1) if item.end_with?('~')
          item
        end
      rescue
        puts "Had trouble with >#{line}"
      end
    end
    puts "Saved: #{file_name}.csv"
  end
end

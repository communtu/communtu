class UmfragePackage < ActiveRecord::Base
  belongs_to :umfrage
  
  def self.exportUmfrage(i)
    UmfragePackage.find_all_by_umfrage_id(i).map {|up| "\"#{up.package}\""}.join(",")
  end
  
  def self.exportR
    puts "list("
    (2..11).each do |i|
      s = UmfragePackage.exportUmfrage(i)
      puts "c(#{s}),"
    end  
    puts ")"
  end
end

# echo "UmfragePackage.exportR" | script/console > umfrage.list

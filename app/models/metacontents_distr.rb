# join table specifying for which distributions the membership
# of a particular package in a bundle holds

class MetacontentsDistr < ActiveRecord::Base
  belongs_to :metacontent
  belongs_to :distribution

  def self.cleanup
    MetacontentsDistr.all.each do |mcd|
      if mcd.metacontent.nil? or mcd.distribution.nil? then
        puts "Removing dangling MetacontentsDistr #{mcd.id}"
        mcd.destroy
      end
    end
  end
  
end

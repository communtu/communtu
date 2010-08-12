# (c) 2008-2010 by Verein Allgemeinbildung e.V., Bremen, Germany
# use, modification or distribution only with permission of the copyright holder

# join table specifying for which derivatives the membership
# of a particular package in a bundle holds

class MetacontentsDerivative < ActiveRecord::Base
  belongs_to :metacontent
  belongs_to :derivative

  def self.cleanup
    MetacontentsDerivative.all.each do |mcd|
      if mcd.metacontent.nil? or mcd.derivative.nil? then
        puts "Removing dangling MetacontentsDerivative #{mcd.id}"
        mcd.destroy
      end
    end
  end

end

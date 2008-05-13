class Metapackage < BasePackage

  has_many   :metacontents, :dependent => :destroy
  has_many   :comments, :dependent => :destroy
  has_many   :base_packages, :through => :metacontents
  belongs_to :category
  belongs_to :distribution
  belongs_to :user
  
  validates_uniqueness_of :scope => :distribution_id
  
  @state = { :pending => 0, :published => 1, :rejected => 2 }
  
  def self.state
    @state
  end
  
  def is_published?
    return self.published == Metapackage.state[:published]
  end
  
  def save_as_temp_meta user_id
    temp = TempMetapackage.new
    temp.name = name
    temp.description = description
    temp.distribution_id = distribution_id
    temp.user_id = user_id
    temp.license_type = license_type
    temp.rating = 0
    
    if temp.save
      metacontents.each do |c|
        t_content = TempMetacontent.new({ :package_id => c.package_id,\
          :temp_metapackage_id => temp.id })
         t_content.save
      end
    end
  end
  
end

class Metapackage < BasePackage

  has_many   :metacontents, :dependent => :destroy
  has_many   :comments, :dependent => :destroy
  has_many   :base_packages, :through => :metacontents
  belongs_to :category
  belongs_to :distribution
  belongs_to :user
  
  validates_uniqueness_of :scope => :distribution_id
  
  @state = { :pending => 0, :published => 1, :rejected => 2 }
  @level = [ "gar nicht", "normal", "erweitert", "Experte", "Freak" ]
  
  def self.state
    @state
  end
  
  def self.level
    @level
  end

  def owned_by? user
    (user_id == user.id)
  end
  
  def is_published?
    return self.published == Metapackage.state[:published]
  end
  
  def migrate(distribution, current_user, failed, doubles)
    ignore = []
    migrate_intern(distribution, current_user, failed, doubles, ignore)
  end
  
  protected
  
  def migrate_intern(distribution, current_user, failed, doubles, ignore)

    meta = Metapackage.find(:first, :conditions => ["name = ? and distribution_id = ?", self.name, distribution.id])
    if not meta.nil? and not ignore.include? meta
        doubles.push(meta)
    end

    meta = Metapackage.new
    meta.name            = name
    meta.user_id         = current_user.id
    meta.distribution_id = distribution.id
    meta.category_id     = category.id
    meta.description     = description
    meta.rating          = rating
    meta.license_type    = license_type
    
    contents = []
    
    base_packages.each do |package|
        if package.class == Package
            migrated = Package.find(:first, :conditions => ["name = ? and distribution_id = ?", package.name, distribution.id])
            if not migrated.nil?
                contents.push(migrated.id)
            else
                failed.push(package)
            end
        else
            package.migrate_intern(distribution, current_user, failed, doubles, ignore)
        end
    end
    
    if not contents.empty?
        meta.save!
        contents.each do |migrated|
            content = Metacontent.new
            content.metapackage_id  = meta.id
            content.base_package_id = migrated
            content.save!
        end
    end
  end
end

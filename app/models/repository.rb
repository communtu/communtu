class Repository < ActiveRecord::Base
  belongs_to :distribution
  has_many :package_distrs, :dependent => :destroy
  has_many :packages, :through => :package_distrs
  validates_presence_of :license_type, :url, :distribution_id
  
  # migrate a repository to a different distribution
  def migrate(dist)
    newurl = url.gsub(self.distribution.short_name.downcase, \
                      dist.short_name.downcase)
    Repository.create({:distribution_id => dist.id,
                       :security_type => security_type,
                       :license_type => license_type,
                       :type => type,
                       :url => newurl,
                       :subtype => subtype,
                       :gpgkey => gpgkey})
  end
  
end

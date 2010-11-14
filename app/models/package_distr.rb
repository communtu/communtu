# (c) 2008-2010 by Verein Allgemeinbildung e.V., Bremen, Germany
# use, modification or distribution only with permission of the copyright holder

# join table linking packages and distributions

# database fields: 
# distribution_id
# filename
# installedsize
# outdated
# package_id
# repository_id
# size
# version

class PackageDistr < ActiveRecord::Base
  belongs_to :package
  belongs_to :repository
  belongs_to :distribution
  has_many :dependencies, :dependent => :destroy
  has_many :package_distrs_architectures, :dependent => :destroy

  has_many :packages, :through => :dependencies, :source => :base_package
  has_many :depends, :through => :dependencies, :source => :base_package, \
    :conditions => 'dependencies.dep_type = 0'    
  has_many :recommends, :through => :dependencies, :source => :base_package, \
    :conditions => 'dependencies.dep_type = 1'
#  has_many :depends_or_recommends, :through => :dependencies, :source => :base_package, \
#    :conditions => 'dependencies.dep_type <= 1'
  has_many :conflicts, :through => :dependencies, :source => :base_package, \
    :conditions => 'dependencies.dep_type = 2'
  has_many :suggests, :through => :dependencies, :source => :base_package, \
    :conditions => 'dependencies.dep_type = 3'

  def assign_depends list
    list.each do |p|
      Dependency.create(:package_distr_id => id, :base_package_id => p.id, :dep_type => 0)
    end
  end

  def assign_recommends list
    list.each do |p|
      Dependency.create(:package_distr_id => id, :base_package_id => p.id, :dep_type => 1)
    end
  end

  def assign_conflicts list
    list.each do |p|
      Dependency.create(:package_distr_id => id, :base_package_id => p.id, :dep_type => 2)
    end
  end
  
  def assign_suggests list
    list.each do |p|
      Dependency.create(:package_distr_id => id, :base_package_id => p.id, :dep_type => 3)
    end
  end

  def depends_or_recommends
    Dependency.find(:all,:conditions => ["package_distr_id = ? and dep_type <= 1",id]).map{|d| d.base_package}
  end
end

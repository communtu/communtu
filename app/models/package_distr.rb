# (c) 2008-2011 byllgemeinbildung e.V., Bremen, Germany
# This file is part of Communtu.

# Communtu is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# Communtu is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero Public License for more details.

# You should have received a copy of the GNU Affero Public License
# along with Communtu.  If not, see <http://www.gnu.org/licenses/>.

# join table linking packages and distributions

# database fields: 
# distribution_id: distribution (although this can also be obtained from the repository)
# filename: file in the repository's pool
# installedsize: size of the package when installed on a computer, in KiB
# outdated: flag used during repository synchronisation
# package_id: package
# repository_id: repository
# size: size of the package file, in bytes
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

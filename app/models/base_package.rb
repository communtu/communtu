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

# database table for storing both Ubuntu packages and Communtu bundles
# (these two are organized as subclasses: package and metapackage).
# Communtu bundles are often called metapackages; this should be changed
# in the future, since the term metapackage is already used by Ubuntu,
# and one bundle leads to many Ubuntu metapackages

# database fields:
# category_id: category of the bundle, only used for Metapackage
# deb_error: has an error occured while debianizing the bundle? Only used for Metapackage
# debianized_version: the latest version of the bundle that has been debianozed. Only used for Metapackage
# debianizing: the bundle is currently debianized. Only used for Metapackage
# default_install: the bundle should be installed by default when its category is selected. Only used for Metapackage
# description: Description as in the Ubuntu repository. Only used for Package. Should be internationalized using description_tid
# description_tid: Internationalized description (using table Translation)
# fullsection: Debian section of package, only used for Package
# icon_file: location of icon illustrating the package, only used for Package
# is_program: is the package a program (in contrast to a library)? Only used for Package
# license_type: 0 = free, 1 = free or proprietary. Only used for Metapackage
# modified: has the bundle been modified since the last debianization? Only used for Metapackage
# name: only used for Package
# name_tid: Internationalized name for bundle (using table Translation) Only used for Metapackage
# p_nofiles: ???
# p_old: ???
# p_recent: ???
# p_vote: ???
# popcon: rating in the Ubuntu popularity contest. Only used for Package
# published: only used for Metapackage
# ratings_count: how many ratings? Only used for Metapackage
# section: abbreviated Debian section, only used for Package
# section_id: internationalized section (for future use)
# security_type: 0 = Ubuntu only, 1 = also Ubuntu community, 2 = also third-party. Only used for Metapackage
# type: "Package" or "Metapackage", distinguishes the two subclasses
# url_tid: ???
# urls: only used for Package
# user_id: creator of the bundle, only used for Metapackage
# version: debian version of the bundle, only used for Metapackage

class BasePackage < ActiveRecord::Base
  require 'set.rb'
  require 'lib/utils.rb'

  has_many :user_packages, :foreign_key => :package_id
  has_many :videos
  has_many :conflicts, :foreign_key => :package_id
  has_many :conflicting_packages, :source => :base_package, :through => :conflicts
  has_many :dependencies, :dependent => :destroy
#  def name
#    translation(self.name_tid)
#  end
        
#  def name_english
#    trans = Translation.find(:first, :conditions => {:translatable_id => self.name_tid, :language_code => "en"})
#    return trans.contents
#  end
                  
#  def description
#    translation(self.description_tid)
#  end                           

    # type of a package, for sorting package lists
  def ptype
    # first display metapackages
    if self.class == Metapackage then
      return 0
    # then program packages
    elsif self.is_program then
      return 1
    # the library packages etc.  
    else return 2
    end
  end

  def debian_name
    if self.class == Metapackage then
      if self.is_published? then
        n="communtu-"+self.name_english
      else 
        n="communtu-private-bundle-"+self.name_english
      end
    else
      n=self.name
    end 
    return BasePackage.debianize_name(n)
  end
  
  def self.debianize_name(n)
    return n.downcase.gsub("ä","ae").gsub("ö","oe").gsub("ü","ue").gsub("ß","ss").gsub(/[^a-z0-9.+-]/, '-')
    # todo: is umlaut elimination really needed?
  end
  
  # packages directly or indirectly installed by this bundle
  def all_recursive_packages
    packages = Set.[]
    all_recursive_packages_aux packages
    return packages
  end
  
  def all_recursive_packages_aux packages
    if !packages.include?(self) then
      packages.add(self)
      if self.class == Package
        self.package_distrs.each do |pd|
          pd.depends_or_recommends.each do |p|
            p.all_recursive_packages_aux packages
          end
        end
      else
        self.base_packages.each do |p|
          p.all_recursive_packages_aux packages
        end
      end
    end
  end


  # packages directly or indirectly installed by this bundle, structured output
  def structured_all_recursive_packages
    packages = {} 
    deps = []
    structured_all_recursive_packages_aux packages, deps
    return packages
  end
  
  def structured_all_recursive_packages_aux packages, deps
    if !deps.include?(self)
      deps.push(self)
      packages_local = {}
      if self.class == Package
        self.package_distrs.each do |pd|
          pd.depends_or_recommends.each do |p|
            p.structured_all_recursive_packages_aux packages_local, deps
          end  
        end
        
      else
        self.base_packages.each do |p|
          p.structured_all_recursive_packages_aux packages_local, deps
        end
      end
      packages[self] = packages_local
    end
  end

end

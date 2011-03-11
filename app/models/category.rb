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

# categories are used to classify Communtu bundles
# in the future, this could be replaced by DebTags

# database fields: 
# description: deprecated
# description_tid: localized description, using table Translation
# link: deprecated
# link_tid: localized link to web page of the Ubuntu community, using table Translation
# main: flag determining whether the category is displayed as main category on the software selection page
# name: deprecated
# name_tid: localized name, using table Translation
# parent_id: link to parent category (nil if we are the root)

class Category < ActiveRecord::Base
  require "lib/utils.rb"
  acts_as_tree :order => "name"
  has_many :metapackages
  belongs_to :category, :foreign_key => 'parent_id'
  has_many :categories, :foreign_key => 'parent_id'
  validates_uniqueness_of :name
  
  def name
    translation(self.name_tid)
  end

  def description
    translation(self.description_tid)
  end

  def link
    trans = translation(self.link_tid)
    if trans == "unknown"
      trans = ""
    end
    return trans
  end

  def parent_name
    if category.nil? then "" else category.name end
  end

  def children
    categories
  end

  def recursive_children
    ch = children
    ([self] + ch + ch.map{|c| c.recursive_children}.flatten).uniq
  end

  def self.draw_tree
    f=File.open("categories.dot","w")
    f.puts "digraph G {"
    Category.find(1).draw_tree_aux(f)
    f.puts "}"
    f.close
  end
  
  def draw_tree_aux(f)
    f.puts '"'+self.name+'";'
    self.children.each do |child|
      f.puts '"'+self.name+'" -> "'+child.name+'";'
      child.draw_tree_aux(f)
    end
  end

  def default_bundles
    (recursive_children.map do |c|
      BasePackage.find_all_by_default_install_and_category_id(true,c.id)
    end).flatten
  end

  def self.root
    first
  end
  
  def category_list_aux(depth=0)
    [{:category=>self,:depth=>depth}] + self.children.map{|c| c.category_list_aux(depth+1)}.flatten
  end

  def self.category_list
    l = root.category_list_aux
    l[1,l.size-1]
  end
end

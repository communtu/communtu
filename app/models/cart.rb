# (c) 2008-2010 by Verein Allgemeinbildung e.V., Bremen, Germany
# use, modification or distribution only with permission of the copyright holder

# database table for temporary storing the current selection of
# Ubuntu packages when creating or editing a bundle

# database fields: 
# metapackage_id
# name

class Cart < ActiveRecord::Base

    has_many :cart_contents, :dependent => :destroy
    has_many :base_packages, :through => :cart_contents
    belongs_to :metapackage

end

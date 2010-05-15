# database table for temporary storing the current selection of
# Ubuntu packages when creating or editing a bundle

class Cart < ActiveRecord::Base

    has_many :cart_contents, :dependent => :destroy
    has_many :base_packages, :through => :cart_contents
    belongs_to :metapackage

end

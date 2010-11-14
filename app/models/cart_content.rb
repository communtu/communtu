# (c) 2008-2010 by Verein Allgemeinbildung e.V., Bremen, Germany
# use, modification or distribution only with permission of the copyright holder

# join table linking carts and packages

# database fields:
# base_package_id
# cart_id

class CartContent < ActiveRecord::Base

    belongs_to :cart
    belongs_to :base_package
        
end

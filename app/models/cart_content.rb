class CartContent < ActiveRecord::Base

    belongs_to :cart
    belongs_to :base_package
        
end

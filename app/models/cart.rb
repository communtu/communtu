class Cart < ActiveRecord::Base

    has_many :cart_contents, :dependent => :destroy
    has_many :base_packages, :through => :cart_contents

end

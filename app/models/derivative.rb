class Derivative < ActiveRecord::Base
  has_many :metacontents_derivatives
  has_many :users
  has_many :debs, :dependent => :destroy  
end

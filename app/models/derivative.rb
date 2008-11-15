class Derivative < ActiveRecord::Base
  has_many :metacontents_derivatives
  has_many :users
end

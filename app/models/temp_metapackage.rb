class TempMetapackage < ActiveRecord::Base
  has_many :temp_metacontents, :dependent => :destroy
  has_one  :user  
  belongs_to :distribution
  validates_presence_of :distribution_id
  validates_presence_of :name
end

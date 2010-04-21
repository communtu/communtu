# mail folders

class Folder < ActiveRecord::Base
  acts_as_tree
  belongs_to  :user
  has_many    :messages, :class_name => "MessageCopy"
end

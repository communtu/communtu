# (c) 2008-2010 by Verein Allgemeinbildung e.V., Bremen, Germany
# use, modification or distribution only with permission of the copyright holder

# mail folders for the Communtu mailing system

class Folder < ActiveRecord::Base
  acts_as_tree
  belongs_to  :user
  has_many    :messages, :class_name => "MessageCopy"
end

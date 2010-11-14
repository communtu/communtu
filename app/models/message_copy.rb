# (c) 2008-2010 by Verein Allgemeinbildung e.V., Bremen, Germany
# use, modification or distribution only with permission of the copyright holder

# copies of mail messages (i.e. if a user stores messages in hix mail box)

# database fields: 
# folder_id
# is_read
# message_id
# recipient_id

class MessageCopy < ActiveRecord::Base
  belongs_to :message
  belongs_to :recipient, :class_name => "User"
  belongs_to :folder
  delegate   :author, :created_at, :subject, :body, :recipients, :to => :message
  #Allows to use MessageCopy.author, .created_at ... 
end

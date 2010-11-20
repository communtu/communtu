# (c) 2008-2010 by Verein Allgemeinbildung e.V., Bremen, Germany
# use, modification or distribution only with permission of the copyright holder

# copies of mail messages (i.e. if a user stores messages in his mail box)

# database fields: 
# folder_id: folder in which message is stored
# is_read: has message been read?
# message_id: pointer to original message
# recipient_id: recipient of message

class MessageCopy < ActiveRecord::Base
  belongs_to :message
  belongs_to :recipient, :class_name => "User"
  belongs_to :folder
  delegate   :author, :created_at, :subject, :body, :recipients, :to => :message
  #Allows to use MessageCopy.author, .created_at ... 
end

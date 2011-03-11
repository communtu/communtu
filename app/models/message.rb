# (c) 2008-2011 byllgemeinbildung e.V., Bremen, Germany
# This file is part of Communtu.

 # Communtu is free software: you can redistribute it and/or modify
 # it under the terms of the GNU Affero Public License as published by
 # the Free Software Foundation, either version 3 of the License, or
 # (at your option) any later version.

 # Communtu is distributed in the hope that it will be useful,
 # but WITHOUT ANY WARRANTY; without even the implied warranty of
 # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 # GNU Affero Public License for more details.

 # You should have received a copy of the GNU Affero Public License
 # along with Communtu.  If not, see <http://www.gnu.org/licenses/>.

# mail messages of the Communtu messanging system

# database fields: 
# author_id: user who created the message
# body
# subject

class Message < ActiveRecord::Base
  belongs_to :author, :class_name => "User"
  has_many :message_copies
  has_many :recipients, :through => :message_copies 
  #Allows to list recipients: e.g. User.find(:first).sent_messages.find(:first).recipients OR

  before_create :prepare_copies
  validates_presence_of :subject, :on => :create, :message => I18n.t(:model_message_0)
  
  attr_accessor  :to # recipient
  attr_accessible :subject, :body, :to
  
  #Builds for every recipient a MessageCopy
  def prepare_copies
    return if to.blank?
    
    to.each do |recipient|
      recipient = User.find_by_login(recipient)
      message_copies.build(:recipient_id => recipient.id, :folder_id => recipient.inbox.id)
    end
  end
end

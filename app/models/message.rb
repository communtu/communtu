# mail messages of the Communtu messanging system

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

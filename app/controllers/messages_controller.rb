class MessagesController < ApplicationController
  def show
    @message = current_user.received_messages.find(params[:id])
    @message.is_read = true;
    @message.save
  end

end

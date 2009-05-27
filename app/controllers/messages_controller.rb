class MessagesController < ApplicationController
  def show
    @message = current_user.received_messages.find(params[:id])
    @message.is_read = true;
    @message.save
  end
  
  def reply
    session[:return_to] = '/inbox'
    
    @original = current_user.received_messages.find(params[:id])
    
    subject = @original.subject.sub(/^(Re: )?/, "Re: ")
    body = @original.body.gsub(/^/, "> ")
    @message = current_user.sent_messages.build(:to => [@original.author.login], :subject => subject, :body => body)
    render :template => "sent/new"
  end
  
  def forward
    session[:return_to] = '/inbox'
    
    @original = current_user.received_messages.find(params[:id])
    
    subject = @original.subject.sub(/^(Fwd: )?/, "Fwd: ")
    body = sprintf("Ursprüngliche Nachricht von %s am %s \n \n", @original.author.login, change_date_time(@original.created_at))
    body += @original.body.gsub(/^/, "> ")
    @message = current_user.sent_messages.build(:subject => subject, :body => body)
    render :template => "sent/new"
  end

end

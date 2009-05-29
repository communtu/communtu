  def safe_system cmd
    if !system cmd
      raise t(:message_0, :scope => [:txt, :lib, :utils])+cmd
    end
  end

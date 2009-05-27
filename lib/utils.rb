  def safe_system cmd
    if !system cmd
      raise _("System-Befehl schlug fehl: ")+cmd
    end
  end

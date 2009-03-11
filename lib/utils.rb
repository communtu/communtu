  def safe_system cmd
    if !system cmd
      raise "System-Befehl schlug fehl: "+cmd
    end
  end

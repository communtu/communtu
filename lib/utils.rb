  def safe_system cmd
    if !system cmd
      raise I18n.t(:lib_utils_0)+cmd
    end
  end

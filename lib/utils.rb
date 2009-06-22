  def safe_system cmd
    if !system cmd
      raise I18n.t(:lib_utils_0)+cmd
    end
  end

   def translation(id)
    tr=Translation.find(:first, :conditions => {:translatable_id => id, :language_code => I18n.locale.to_s })
    if tr.nil? then
      tr=Translation.find(:first, :conditions => {:translatable_id => id, :language_code => "en" })
        if tr.nil? then
          return "unknown"
        end
    end
    return tr.contents
  end

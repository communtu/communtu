class Architecture < ActiveRecord::Base
  has_many :package_distrs_architectures, :dependent => :destroy

  DEFAULT_ARCH_NAME = "i386"

  def self.browser_architecture(s)
    if s.nil? then
      return nil
    end
    s1 = s.downcase
    Architecture.all.each do |a|
      case a.name
        when "i386" then n = "686"
        when "amd64" then n = "86_64"
      end
      if !s1.index(n.downcase).nil? then
        return a
      end
    end
    return nil
  end

  def self.browser_architecture_with_default(s)
    a = Architecture.browser_architecture(s)
    if a.nil? then
      return Architecture.find_by_name(DEFAULT_ARCH_NAME)
    else
      return a
    end
  end

  def self.browser_info(s)
    a = Architecture.browser_architecture(s)
    if a.nil? then
      return ""
    else
      return a.name
    end
  end

end

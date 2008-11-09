class BasePackage < ActiveRecord::Base
  has_many :user_packages, :foreign_key => :package_id
  
    # type of a package, for sorting package lists
  def ptype
    # first display metapackages
    if self.class == Metapackage then
      return 0
    # then program packages
    elsif self.is_program then
      return 1
    # the library packages etc.  
    else return 2
    end
  end

end

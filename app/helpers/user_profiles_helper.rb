# (c) 2008-2010 by Verein Allgemeinbildung e.V., Bremen, Germany
# use, modification or distribution only with permission of the copyright holder

module UserProfilesHelper
  
    def check_bundles root
      root.default_bundles.map do |b|
         "$('post_#{b.id}').checked=$('categories_#{root.id.to_s}').checked"
      end.join("; ")
    end
  
end

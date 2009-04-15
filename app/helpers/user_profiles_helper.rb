module UserProfilesHelper
  
    def selected? category, selection
        return selection.key?(category)
    end

    def show_packages2 packages, selection
        pub_packages = packages.select{|m| m.is_published? or m.user_id == current_user.id or is_admin? }
        out = ""
        # puts "PACKAGES: " + pub_packages.size.to_s
        pub_packages.each do |package|
            selected = selection.include? package
            out += "<div id='selected' class='suggestionPackage'>\n"
                out += "<ul class='suggestionPackage'>"
                out += "<li class='suggestionPackage'> " + check_box_tag("post[" + package.id.to_s + "]", 1, selected) + "</li>\n"
                out += "<li class='suggestionPackage'>" + link_to(package.name,metapackage_url(:id => package.id)) + "</li>\n"
                out += "</ul>"
            out += "</div>\n"
            out += "<div id='unselected' class='suggestionDescription'>"
                out += package.description
            out += "</div>"
        end
        return out
    end

    def show_selection_subtree2 root, selection, depth
        
        out = "<div class='suggestionHeader'><ul class='suggestionHeader'>\n"
            out += "<li class='suggestionCollapse'><img src='/images/add.png' width='10' height='10' onclick=\"['packages" + \
                root.name + "'].each(Element.toggle)\"></li>\n"
            out += "<li class='suggestionHeader'><b>" + root.name + "</b></li>\n"
        out += "</ul></div>\n"
        
        out += "<div class='suggestionPackages'  style='display: none' id='packages" + root.name + "'>\n"

        out += show_packages2 root.metapackages, selection

        root.children.each do |child|
            out += show_selection_subtree2 child, selection, (depth + 1)
        end

        out += "</div>\n"
        
        return out
    end

    def show_suggestion2 root, selection
        
        out = "<div class='suggestion'>\n"
        
        if root.children.nil?
           return out + "</div>\n"
        end

        root.children.each do |child|
           out += show_selection_subtree2 child, selection, 0
        end
   
        return out + "</div>\n"
    end
  
end

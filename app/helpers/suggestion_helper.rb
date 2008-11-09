module SuggestionHelper

    def selected? category, selection
        return selection.key?(category)
    end

    def show_packages packages, selected
        out = ""
        packages.each do |package|
            out += "<div id='selected' class='suggestionPackage'>\n"
                out += "<ul class='suggestionPackage'>"
                out += "<li class='suggestionPackage'>" + check_box_tag("post[" + package.id.to_s + "]", 0, selected) + "</li>\n"
                out += "<li class='suggestionPackage'>" + link_to(package.name,metapackage_url(:id => package.id)) + "</li>\n"
                out += "</ul>"
            out += "</div>\n"
            out += "<div id='unselected' class='suggestionDescription'>"
                out += package.description
            out += "</div>"
        end
        return out
    end

    def show_selection_subtree root, selection, depth
        
        out = "<div class='suggestionHeader'><ul class='suggestionHeader'>\n"
            out += "<li class='suggestionCollapse'><img src='/images/add.png' width='10' height='10' onclick=\"['packages" + \
                root.name + "'].each(Element.toggle)\"></li>\n"
            out += "<li class='suggestionHeader'><b>" + root.name + "</b></li>\n"
        out += "</ul></div>\n"
        
        out += "<div class='suggestionPackages' id='packages" + root.name + "'>\n"
        
        selected = selection[root]
        if selected.nil? then selected = [] end
                
        if selected? root, selection
            out += show_packages selected, true
        end
        out += show_packages root.metapackages.select {|meta| not selected.include? meta and meta.distribution == @distribution }, false
        
#        root.children.each do |child|
#            out += show_selection_subtree child, selection, (depth + 1)
#        end
        
        out += "</div>\n"
        
        return out
    end

    def show_suggestion root, selection
        
        out = "<div class='suggestion'>\n"
        
        if root.children.nil?
           return out + "</div>\n"
        end
        
        root.children.each do |child|
            if not child.metapackages.nil? and not child.metapackages.size == 0
                out += show_selection_subtree child, selection, 0
            end
        end
   
        return out + "</div>\n"
    end

end


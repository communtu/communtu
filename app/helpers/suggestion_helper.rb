module SuggestionHelper

    def selected? category, selection
        return selection.key? category
    end

    def show_packages packages, selected
        out = ""
        packages.each do |package|
            out += "<tr>\n"
                out += "<td width='15' bgcolor='#fff7cd'/>\n"
                out += "<td width='20' class='suggestionTop' />\n"
                out += "<td class='suggestionTop'>" + package.name + "</td>\n"
                out += "<td class='suggestionTop'>\n"
                    out += check_box_tag "post[" + package.id.to_s + "]", 0, selected
                out += "</td>\n"
            out += "</tr>\n"
            out += "<tr>"
                out += "<td width='15' bgcolor='#fff7cd' />\n"
                out += "<td width='20' class='suggestionBottom'/>\n"
                out += "<td colspan='2' class='suggestionBottom'>" + package.description + "</td>"
            out += "</tr>"
        end
        return out
    end

    def show_selection_subtree root, selection, depth
    
        out = "<tr>\n"
            out += "<td width='15' bgcolor='#fff7cd' />"
            out += "<td colspan='3' class='suggestion" + depth.to_s + "'><b>" + root.name + "</b></td>\n"
        out += "</tr>\n"
        
        selected = selection[root]
        if selected.nil? then selected = [] end
                
        if selected? root, selection
            out += show_packages selected, true
        end
        out += show_packages root.metapackages.select {|meta| not selected.include? meta}, false
        
        root.children.each do |child|
            out += show_selection_subtree child, selection, (depth + 1)
        end
        
        return out
    end

    def show_suggestion root, selection
        
        out = "<table width='100%' cellspacing='0' class='suggestion'>\n"
        
        if root.children.nil?
            return out
        end
        
        root.children.each do |child|
            out += show_selection_subtree child, selection, 0
        end
        
        return out + "</table>\n"
    end

end

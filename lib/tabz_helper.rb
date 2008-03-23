module TabzHelper

    def render_tabz(symbol, user_data)
    
        tabbing = symbol.to_tabz
        current = tabbing.tabs[params[:id].to_i]
        result  = tag("div", {}, true)
        result << tag("ul", {:class => "tabz"}, true)
        
        n = 0
        tabbing.tabs.each do |tab|
        
            result << tag("li", {:class => "tabz"}, true)
            result << link_to(tab.title, build_url(n), {})
            result << "</li>\n"
            
            n = n + 1
        
        end
        
        result << "</ul></div>\n"
        result << tag("div", {:class => "tabz_content"}, true)
        current.prepare_to_show(user_data)
        result << capture do render(:partial => current.partial, :locals => current.locals) end
        result << "</div>\n"
    
    end
    
    private
    
    def build_url(n)
        request.request_uri.chop + n.to_s
    end

end

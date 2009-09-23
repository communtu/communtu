module TabzHelper

    def render_tabz(symbol, user_data)
    
        tabbing = symbol.to_tabz
        current = tabbing.tabs[params[:id].to_i]
        result  = tag("div", {}, true)
        result << tag("ul", {:class => "tabz"}, true)
        
        n = 0
        m = 3
        tabbing.tabs.each do |tab|
            go_title = tab.title
            if current == tabbing.tabs[n]
              result << tag("li", {:class => "tabz_select"}, true)
              result << link_to(tab.title, build_url(tabbing, n), {})
            result << "</li>\n"
            elsif n == 0
              result << tag("li", {:class => "tabz"}, true)
              result << link_to(tab.title, build_url(tabbing, n), {})
            result << "</li>\n"
            #elsif go_title != tab.title[n]
            # p = u
            elsif n <= m and go_title != "Meine Bündel"
            #  result << go_title
              result << tag("li", {:class => "tabz"}, true)
              result << link_to(tab.title, build_url(tabbing, n), {})
            result << "</li>\n"
            else
              #result << tag("li", {:class => "tabz"}, true)
            end
           
            n = n + 1
     
        end

        result << "</ul></div>\n"
       # result << tag("div", {:class => "tabz_content", :id => "tabz_content"}, true)
        current.prepare_to_show(user_data)
        result << capture do render(:partial => current.partial, :locals => current.locals) end
        result << "</div>\n"
    
    end
    
    private
    
    def build_url(tabbing, n)
        tabbing.base.gsub(/:([a-z|A-Z|_]*)/) { |match| params[$1] } + "/" + n.to_s
    end

end

require 'singleton'

# extend symbol class to convert symbols into tab model instances
class Symbol 
    
    def to_tabz
        name = self.id2name + "_tabz"
        eval(name.camelcase.instance)
    end
    
end

module Tabz

    # a single tab that contains all information to render itself
    class Tab
    
        def initialize &block
    
            # tab title and partial to render
            attr_reader :title, :partial
            # a block that gets evaluated before each display
            attr_reader :evaulator, :locals
            
            instance_eval(&block)
        
        end
        
        # set the tab title
        def titled(title)
            @title = title
        end
        
        # set the partial used to render the tab
        def looks_like(partial)
            @partial = partial
        end
            
        # sets the block that find the data for the rendering partial
        def with_data(eval)
            @evaluator = eval
        end
   
        # sets the data used to display the tab partial     
        def set_to(data)
            @locals = data
        end
    
        # called before rendering to update the data context for the tab partial
        def prepare_to_show
            instance_eval(&block)
        end
    end

    # the base for tab models
    class Base
        include Singleton

        attr_reader :tabs
    
        def initialize
            @tabs = []
        end
   
        # add a tab to the store (should be added in order)
        def self.add_tab &block
            @tabs.push(Tabz::Tab.new(&block))
        end
        
        # get a tab with a certain id
        def self.get_tab(id)
           @tabs[id]
        end
    end
end

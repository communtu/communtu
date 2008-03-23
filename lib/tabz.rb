require 'singleton'

# extend symbol class to convert symbols into tab model instances
class Symbol 
    
    def to_tabz
        name = self.id2name + "_tabz"
        eval(name.camelcase).instance
    end
    
end

module Tabz

    # a single tab that contains all information to render itself
    class Tab
    
        attr_reader :title, :partial, :evaluator, :locals
    
        def initialize &block
                
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
        def with_data(&block)
            @evaluator = block
        end
   
        # sets the data used to display the tab partial     
        def set_to(data)
            @locals = data
        end
    
        # called before rendering to update the data context for the tab partial
        def prepare_to_show(user_data)
            @user_data = user_data
            instance_eval &@evaluator
        end
    end

    # the base for tab models
    class Base
        include Singleton

        attr_accessor :tabs, :base, :controler
   
        def self.resides_in base
            instance.base = base
        end
   
        # add a tab to the store (should be added in order)
        def self.add_tab &block
            instance.tabs = [] if instance.tabs.nil?
            instance.tabs << Tabz::Tab.new(&block)
        end
        
        private 
        
        def initialize
            @tabs = []
            @base = "/tabs"
        end
        
    end
end

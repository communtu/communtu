class Cart

    attr_reader :name
    attr_reader :content

    def initialize
        @content = []
        @name    = "New Package"
    end

    def add_to_cart package
        @content.push(package)
    end
    
    def rem_from_cart package
        @content.delete(package)
    end
    
    def clear
        @content = []
    end
    
    def content_by_name
        @content.sort { |p0,p1| p0.name <=> p1.name }
    end
        
end

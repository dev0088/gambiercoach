module ActiveRecord
  
  class Errors
    def full_error_string
      error_string = ""
      first = true
      self.each_full{ |msg|
        if !first
          error_string += "; "
        end
        error_string += msg
        first = false          
      }
      return error_string
    end
    
    def full_html_error_string
      return full_error_string.gsub("'", "&#39;")
    end
  end
  
end
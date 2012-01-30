module LiveCDsHelper
  def invert(params,by)
    if params[:by] == by
      if params[:order] == "asc"
        "desc"
      else
        "asc"
      end 
    else
      "asc"
    end
  end
end

module ApplicationHelper

  # Change this method to alter the 'tiles' shown in browser when navigating through AIR
  def title
    params[:controller]
  end

end

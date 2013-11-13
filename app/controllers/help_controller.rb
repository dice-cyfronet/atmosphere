class HelpController < ApplicationController
  skip_authorization_check

  def index

  end

  def api
    authenticate_user!

    @category = params[:category]
    @category = "README" if @category.blank?

    if File.exists?(Rails.root.join('doc', 'api', @category + '.md'))
      render 'api'
    else
      not_found!
    end
  end
end

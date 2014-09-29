class HelpController < ApplicationController
  skip_authorization_check

  before_filter :authenticate_user!

  def index

  end

  def api
    @category = params[:category]
    @category = "README" if @category.blank?

    if File.exists?(Rails.root.join('doc', 'api', @category + '.md'))
      render 'api'
    else
      not_found!
    end
  end
end

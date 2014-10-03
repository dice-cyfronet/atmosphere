class Atmosphere::HelpController < Atmosphere::ApplicationController
  skip_authorization_check
  layout 'layouts/atmosphere/application'

  before_filter :authenticate_user!

  def index

  end

  def api
    if api_exists?
      @doc_file = doc_file
      render 'api'
    else
      not_found!
    end
  end

  private

  def api_exists?
    File.exists?(main_doc_file) || File.exists?(engine_doc_file)
  end

  def doc_file
    return main_doc_file if File.exists?(main_doc_file)
    return engine_doc_file if File.exists?(engine_doc_file)
  end

  def main_doc_file
    @main_doc_file ||= Rails.root.join('doc', 'api', category + '.md')
  end

  def engine_doc_file
    @engine_doc_file ||= Atmosphere::Engine.root.join('doc', 'api', category + '.md')
  end

  def category
    @category ||= params[:category].blank? ? "README" : params[:category]
  end
end

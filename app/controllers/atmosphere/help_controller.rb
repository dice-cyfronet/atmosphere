class Atmosphere::HelpController < Atmosphere::ApplicationController
  skip_authorization_check
  layout 'layouts/atmosphere/application'

  before_action :authenticate_user!

  def index
  end

  def api
    if api_exists?
      @doc_file = doc_file
      @categories = categories
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
    @main_doc_file ||= category_path(main_root)
  end

  def main_root
    Rails.root.join('doc', 'api')
  end

  def category_path(root)
    root.join("#{category}.md")
  end

  def engine_doc_file
    @engine_doc_file ||= category_path(engine_root)
  end

  def engine_root
    Atmosphere::Engine.root.join('doc', 'api')
  end

  def category
    @category ||= params[:category].blank? ? 'README' : params[:category]
  end

  def categories
    @categories = basenames_from_dir(main_root) |
                  basenames_from_dir(engine_root)
  end

  def basenames_from_dir(dir)
    if Dir.exist?(dir)
      Dir["#{dir}/*.md"].map { |f| File.basename(f, '.md') }
    else
      []
    end
  end
end

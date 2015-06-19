class AuthenticatedUserController < ApplicationController
  # load region, domain and project if given
  prepend_before_filter do
    # redirect to the same url with default domain unless domain_id is given
    redirect_to url_for(params.merge(domain_id: MonsoonOpenstackAuth.default_domain.id)) unless params[:domain_id]
    
    @region     ||= MonsoonOpenstackAuth.configuration.default_region
    @domain_id  ||= params[:domain_id]
    @project_id ||= params[:project_id]    
  end
   
  authentication_required domain: -> c { c.instance_variable_get("@domain_id") }, project: -> c { c.instance_variable_get('@project_id') }
  
  before_filter :check_terms_of_use
  
  include OpenstackServiceProvider::Services  
  
  rescue_from "Excon::Errors::Forbidden", with: :handle_api_error
  rescue_from "Excon::Errors::InternalServerError", with: :handle_api_error
  rescue_from "MonsoonOpenstackAuth::ApiError", with: :handle_auth_error
    
  protected
  
  def handle_api_error(exception)
    @errors = ApiErrorParser.handle(exception)
    render template: 'authenticated_user/error'
  end
  
  def handle_auth_error(exception)
    @errors = {exception.class.name => exception.message}
    render template: 'authenticated_user/error'
  end
  
  def check_terms_of_use
    unless services.identity.has_projects?
      # user has no project yet. 
      # We assume that it is a new user -> redirect to terms of use page.
      session[:requested_url] = request.env['REQUEST_URI']
      redirect_to new_user_path
    end
  end
  
end
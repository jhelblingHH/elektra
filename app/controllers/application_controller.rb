# This module adds two methods for exception handling.
# With rescue_and_render_exception_page it is possible to catch
# exceptions and display a well designed exception page.
# The render_exception_page method implements the displaying of an exception.
module ErrorRenderer
  # add instance and class methods after this module was included or extended.
  def self.included(base)
    base.send("extend",ClassMethods)
    base.send("include", InstanceMethods)
  end
  def self.extended(base)
    base.send("extend",ClassMethods)
    base.send("include", InstanceMethods)
  end

  # instance methods
  module InstanceMethods
    def render_exception_page(exception,map={})
      raise exception if Rails.env.development? && ENV.key?('NO_EXCEPTION_PAGE')
      value = lambda do |param|
        v = map[param.to_sym] || map[param.to_s]
        return nil if v.nil?
        return exception.send(v).to_s if v.kind_of?(Symbol)
        return v.call(exception,self).to_s if v.kind_of?(Proc)
        return v.to_s
      end

      begin
        @title = value.call(:title) || exception.class.name.split('::').last.humanize
        @description = value.call(:description) || (exception.message rescue exception.to_s)
        @details = value.call(:details) || exception.class.name+"\n"+(exception.backtrace rescue '').join("\n")
        @exception_id = value.call(:exception_id) || request.uuid
        @warning = value.call(:warning) || false
        @status = value.call(:status) || (exception.respond_to?(:status)? exception.status: 503)
      rescue => e
        @title = e.class.name.split('::').last.humanize
        @description = e.message
        @details = e.class.name+"\n"+(e.backtrace rescue '').join("\n")
        @exception_id = request.uuid
        @warning = false
        @status = 503
      end

      status = @status

      unless @warning
        logger.error(@exception_id+": "+@title+". "+@description)

        unless map[:sentry]==false
          Raven::Rack.capture_exception(exception, env)
          @exception_id = Raven.last_event_id if Raven.last_event_id
        end
        @sentry_event_id   = Raven.last_event_id
        @sentry_public_dsn = URI.parse(ENV['SENTRY_DSN']).tap {|u| u.password=nil}.to_s if ENV['SENTRY_DSN']
        @sentry_user       = { name: current_user.full_name || current_user.name, email: current_user.email } if current_user

        if request.xhr? && params[:polling_service]
          render "/application/exceptions/error_polling.js", format: "JS"
        else
          respond_to do |format|
            format.html { render '/application/exceptions/error.html' }
            format.js { render "/application/exceptions/error.js" }
            format.json {render json: {error: @description}, status: @status}
          end
        end
      else
        if request.xhr? && params[:polling_service]
          render "/application/exceptions/error_polling.js", format: "JS"
        else
          respond_to do |format|
            format.html { render '/application/exceptions/warning.html' }
            format.js { render "/application/exceptions/warning.js" }
            format.json { render json: {error: @description}, status: @status }
          end
        end
      end
    end
  end

  # class methods
  module ClassMethods
    # This method is used in controllers to catch errors and render error page.
    # It differentiates between html, modal, js and polling errors.
    # Request vom Polling service which end up in error will display Flash-Errors.
    # GET-Requests for modal content will show errors inside modal window.
    # JS-POST requests (e.g.: remote: true) will display error dialog.
    def rescue_and_render_exception_page(*exception_classes)
      exception_classes = exception_classes.first if exception_classes.first.is_a?(Array)
      exception_mapping = {}
      klasses = []

      exception_classes.each do |exception_class|
        if exception_class.is_a?(Hash)
          exception_mapping[exception_class.keys.first.to_s]=exception_class.values.first
          klasses << exception_class.keys.first.to_s
        else
          klasses << exception_class
        end
      end

      rescue_from *klasses do |exception|
        map = exception_mapping[exception.class.name]
        unless map
          klass = nil
          exception_mapping.each do |class_name,mapping|
            found_class = eval(class_name)
            next if klass and found_class > klass

            if found_class>exception.class
              map = mapping
            end
          end
          map ||= {}
        end

        render_exception_page(exception,map)
      end
    end
  end
end

require 'core/audit_logger'
# This class implements functionality to support modal views.
# All subclasses which require modal views should inherit from this class.
class ApplicationController < ActionController::Base
  layout 'application'
  include ApplicationHelper

  # includes services method
  # use: services.SERVICE_NAME.METHOD_NAME (e.g. services.identity.auth_projects)
  include APIClient
  include Services
  include ServiceUser
  include CurrentUserWrapper
  include Core::Paginatable

  extend ErrorRenderer

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  helper_method :modal?, :plugin_name

  # check if the requested domain is the same as that of the current user.
  before_filter :same_domain_check

  # catch all api errors and render exception page
  rescue_and_render_exception_page [
    { "Excon::Error" => { title: 'Backend Service Error' }},
    { "Fog::OpenStack::Errors::ServiceError" => { title: 'Backend Service Error' }}
  ]

  def modal?
    if @modal.nil?
      @modal = (request.xhr? and params[:modal]) ? true : false
    end
    @modal
  end

  def render(*args)
    options = args.extract_options!
    options.merge! layout: 'modal' if modal?
    super *args, options
  end

  def redirect_to(options = {}, response_status = {})
    if request.format==Mime::JSON or modal? or params[:polling_service] or params[:do_not_redirect]
      head :ok, location: url_for(options)
    else
      super options, response_status
    end
  end

  def plugin_name
    if @plugin_name.blank?
      tokens = self.class.name.split('::').collect{|token| token.underscore}
      @plugin_name = tokens.find{|t| Core::PluginsManager.plugin?(t)}
    end
    @plugin_name
  end

  protected

  def same_domain_check
    if current_user and current_user.user_domain_id and service_user and service_user.domain_id
      if current_user.user_domain_id!=service_user.domain_id
        # requested domain differs from the domain of current user
        @current_domain_name = current_user.user_domain_name
        @new_domain_name = service_user.domain_name

        @domain_switch = true
        # render domain switch view
        render template: 'application/domain_switch'
      end
    end
  end
end

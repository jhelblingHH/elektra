module Core
  module ServiceLayer
    module Driver
      # this class maps the response to a given container class
      # e.g. list_domains -> [Indentity::Domain], get_domain -> Indentity::Domain
      class Mapper
        def initialize(driver,klass,additional_attributes={})
          puts "[driver] -> mapper -> init" if ENV['DRIVER_LAYER_DEBUG']
          @driver=driver
          @klass=klass
          @additional_attributes = additional_attributes
        end

        def map(response)
          puts "[driver] -> mapper -> map" if ENV['DRIVER_LAYER_DEBUG']
          if response.is_a?(Array)
            response.collect{|attributes| @klass.new(@driver,attributes.merge(@additional_attributes))}
          elsif response.is_a?(Hash)
            @klass.new(@driver,response.merge(@additional_attributes))
          else
            nil  
          end
        end

        def method_missing(method_sym, *arguments, &block)
          puts "[driver] -> mapper -> method_missing" if ENV['DRIVER_LAYER_DEBUG']
          if arguments.count>0
            map(@driver.send(method_sym, *arguments, &block))
          else
            map(@driver.send(method_sym,&block))
          end
        end
      end

      # Base Driver Class
      # TODO catch other errors (depending on driver)
      class Base
        def initialize(params={})
          puts "[driver] -> base -> init" if ENV['DRIVER_LAYER_DEBUG']
          @auth_url       = params[:auth_url]
          @region         = params[:region]
          @token          = params[:token]
          @domain_id      = params[:domain_id]
          @project_id     = params[:project_id]
        end

        def handle_response(&block)
          puts "[driver] -> base -> handle_response" if ENV['DRIVER_LAYER_DEBUG']
          response = block.call
          return nil unless response

          response
        rescue => e
          raise e unless handle_api_errors?
          raise Core::ServiceLayer::Errors::ApiError.new(e)
        end

        # TODO This is a crutch to enable the object-storage plugin to display plausible, informative errors when backend calls fail.
        def handle_api_errors?
          true # by default, can be overridden by subclass
        end

        # use a mapper for response
        def map_to(klass, additional_attributes={})
          puts "[driver] -> base -> map_to" if ENV['DRIVER_LAYER_DEBUG']
          unless (klass<=Core::ServiceLayer::Model)
            raise Core::ServiceLayer::Errors::BadMapperClass.new("#{klass} is not a subclass of Core::ServiceLayer::Model")
          end
          Mapper.new(self,klass,additional_attributes)
        end
      end
    end
  end
end

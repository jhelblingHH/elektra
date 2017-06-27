require_relative '../strip_attributes'

module Core
  module ServiceLayer
    class Model2
      extend ActiveModel::Naming
      extend ActiveModel::Translation
      include ActiveModel::Conversion
      include ActiveModel::Validations
      include Core::StripAttributes
      include ActiveModel::Validations::Callbacks

      strip_attributes

      attr_reader :errors

      def initialize(params=nil)
        self.attributes=params
        # get just the name of class without namespaces
        @class_name = self.class.name.split('::').last.underscore

        # create errors object
        @errors = ActiveModel::Errors.new(self)

        # execute after callback
        after_initialize
      end

      def id
        @id
      end

      def id=(id)
        @id=id
      end

      def attributes
        @attributes.merge(id:@id)
      end

      def as_json(options=nil)
        attributes
      end

      # look in attributes if a method is missing
      def method_missing(method_sym, *arguments, &block)
        attribute_name = method_sym.to_s
        attribute_name = attribute_name.chop if attribute_name.ends_with?('=')

        if arguments.count>1
          write(attribute_name, arguments)
        elsif arguments.count>0
          write(attribute_name, arguments.first)
        else
          read(attribute_name)
        end
      end

      def respond_to?(method_name, include_private = false)
        keys = @attributes.keys
        method_name.to_s=="id" or keys.include?(method_name.to_s) or keys.include?(method_name.to_sym) or super
      end

      def requires(*attrs)
        attrs.each do |attribute|
          if self.send(attribute.to_s).nil?
            raise Core::ServiceLayer::Errors::MissingAttribute.new("#{attribute} is missing")
          end
        end
      end

      def api_error_name_mapping
        {
            #"message": " ",
            "Message": "message"
        }
      end

#      def save
#        # execute before callback
#        before_save
#
#        success = self.valid?
#
#        if success
#          if self.id.nil?
#            success = perform_create
#          else
#            success = perform_update
#          end
#        end
#
#        return success & after_save
#      end
#
#      def update(attributes={})
#        attributes.each do |key, value|
#          send("#{key.to_s}=", value)
#        end
#        return save
#      end
#
#      alias_method :update_attributes, :update
#
#      def destroy
#        requires :id
#        # execute before callback
#        before_destroy
#
#        error_names = api_error_name_mapping
#        begin
#          if id
#            perform_driver_delete(id) #@driver.send("delete_#{@class_name}", id)
#            return true
#          else
#            self.errors.add(:id, "Could not destroy #{@class_name}. Id not presented.")
#            return false
#          end
#        rescue => e
#          raise e unless defined?(@driver.handle_api_errors?) and @driver.handle_api_errors?
#
#          Core::ServiceLayer::ApiErrorHandler.get_api_error_messages(e).each{|message| self.errors.add(:api, message)}
#          return false
#        end
#      end

      def attributes=(new_attributes)
        @attributes = (new_attributes || {}).clone
        # delete id from attributes!
        new_id = nil
        if @attributes["id"] or @attributes[:id]
          new_id = (@attributes.delete("id") or @attributes.delete(:id))
        end
        # if current_id is nil then overwrite it with new_id.
        @id = new_id if (@id.nil? or (@id.is_a?(String) and @id.empty?))
      end

      def escape_attributes!
        escaped_attributes = (@attributes || {}).clone
        escaped_attributes.each{|k,v| @attributes[k]=escape_value(v)}
      end

      # callbacks
      def before_create;
        return true;
      end

      def before_destroy;
        return true;
      end

      def before_save;
        return true;
      end

      def after_initialize;
        return true;
      end

      def after_create;
        return true;
      end

      def after_save;
        return true;
      end

      def created_at
        value = read("created") || read("created_at")
        DateTime.parse(value) if value
      end

      def pretty_created_at
        Core::Formatter.format_modification_time(created_at) if created_at
      end

      def updated_at
        value = read("updated") || read("updated_at")
        DateTime.parse(value) if value
      end

      def pretty_updated_at
        Core::Formatter.format_modification_time(updated_at) if updated_at
      end

      def attributes_for_create
        @attributes
      end

      def attributes_for_update
        @attributes
      end

      def write(attribute_name, value)
        @attributes[attribute_name.to_s] = value
      end

      def read(attribute_name)
        value = @attributes[attribute_name.to_s]
        value = @attributes[attribute_name.to_sym] if value.nil?
        value
      end

      def escape_value(value)
        value = CGI::escapeHTML(value) if value.is_a?(String)
        value
      end

      def pretty_attributes
        JSON.pretty_generate(@attributes.merge(id: self.id))
      end

      def to_s
        pretty_attributes
      end

      def attribute_to_object(attribute_name, klass)
        value = read(attribute_name)

        if value
          if value.is_a?(Hash)
            return klass.new(value)
          elsif value.is_a?(Array)
            return value.collect { |attrs| klass.new(attrs) }
          end
        end
        return nil
      end

      def map_to(*args)
        self.class.map_to(*args)
      end

      def self.map_to(klazz,data,additional_attributes={})
        if data.is_a?(Array)
          data.collect{|item| klazz.new(item.merge(additional_attributes))}
        elsif data.is_a?(Hash)
          klazz.new(data.merge(additional_attributes))
        else
          data
        end
      end

      def self.debug(message)
        puts message if ENV['MODEL_DEBUG']
      end

    end
  end
end

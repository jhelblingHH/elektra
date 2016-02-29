module ObjectStorage
  class Container < Core::ServiceLayer::Model

    # The following properties are known:
    #   - name
    #   - object_count
    #   - bytes_used
    #   - metadata (Hash)
    # The id() is identical to the name() if the container is persisted.

    validates_presence_of :name
    validates_numericality_of :object_count_quota, greater_than_or_equal_to: -1
    validate do
      # http://developer.openstack.org/api-ref-objectstorage-v1.html#createContainer
      errors[:name] << 'may not contain slashes' if name.include?('/')
      errors[:name] << 'may not contain more than 256 characters' if name.size > 256
      errors[:bytes_quota] << "is invalid: #{@bytes_quota_validation_error}" if @bytes_quota_validation_error
    end

    def object_count
      read(:object_count).to_i
    end

    def object_count_quota
      read(:object_count_quota || "-1").to_i
    end

    def bytes_used
      read(:bytes_used).to_i
    end

    def bytes_quota
      read(:bytes_quota || "-1").to_i
    end

    def bytes_quota=(new_value)
      if new_value.is_a?(String)
        begin
          new_value = Core::DataType.new(:bytes).parse(new_value)
          @bytes_quota_validation_error = nil
        rescue ArgumentError => e
          # errors.add() only works during validation, so store this error for later
          @bytes_quota_validation_error = e.message
          return
        end
      end
      super(new_value)
    end

    def initialize(driver, attributes={})
      super(driver, attributes)
      # the driver needs the previous set of metadata to calculate the changes during update_container()
      @original_metadata = metadata
    end

    def update_attributes
      super.merge('original_metadata' => @original_metadata)
    end

    def empty?
      @driver.objects(name, limit: 1).count == 0
    end

    def empty!
      # bulk-delete all objects in the container
      container_name = self.name
      targets = @driver.objects(container_name).map do |obj|
        { container: container_name, object: obj['path'] }
      end
      @driver.bulk_delete(targets)
    end

  end
end

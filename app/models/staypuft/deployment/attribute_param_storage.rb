module Staypuft
  module Deployment::AttributeParamStorage
    def param_scope
      raise NotImplementedError
    end

    def param_attr(*names)
      names.each do |name|
        ivar_name  = :"@#{name}"
        param_name = "ui::#{param_scope}::#{name}"

        define_method name do
          instance_variable_get(ivar_name) or
              instance_variable_set(ivar_name,
                                    hostgroup.group_parameters.find_by_name(param_name).try(:value))
        end

        define_equals name

        after_save do
          value = send(name)
          # FIXME: not sure if hard-coding false is correct here, but without it, false was
          # being set to 'nil', breaking boolean values (empty arrays may prove to be a similar problem)
          if value.blank? && !(value == false)
            hostgroup.
                group_parameters.
                find_by_name(param_name).try(:destroy)
          else
            param = hostgroup.
                group_parameters.
                find_or_initialize_by_name(param_name)
            param.update_attributes!(value: value)
          end
        end
      end
    end

    def param_attr_array(*names)
      names.each do |name|
        ivar_name = :"@#{name}"
        param_base_name = "ui::#{param_scope}::#{name}"

        define_method name do
          instance_variable_get(ivar_name) or
          begin
            params = hostgroup.group_parameters.where(['name LIKE ?', "#{param_base_name}%"])
            ivar = []
            params.each do |param|
              if param.try(:value)
                full, index, param_name = *param.name.match(/#{param_base_name}::(\d+)::(.*)/)
                ivar[index.to_i] ||= {}
                ivar[index.to_i][param_name] = param.value
              end
            end
            instance_variable_set(ivar_name, ivar)
          end
        end

        define_equals name

        after_save do
          values = send(name)
          # Delete all params since array can shrink
          params = hostgroup.group_parameters.where(['name LIKE ?', "#{param_base_name}%"])
          params.each do |param|
            param.try(:destroy)
          end
          if not values.blank?
            values.each_with_index do |value, index|
              value.each do |k,v|
                param = hostgroup.
                    group_parameters.
                        find_or_initialize_by_name( "#{param_base_name}::#{index}::#{k}")
                param.update_attributes!(value: v)
              end
            end
          end
        end
      end
    end

    private

    def define_equals(name)
      define_method "#{name}=" do |value|
        instance_variable_set(:"@#{name}", value)
      end
    end
  end
end


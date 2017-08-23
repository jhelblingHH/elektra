module Identity
  module ProjectsHelper

    # This method loads remote projects via ajax into a new created div.
    def remote_projects(options={})
      container_id = SecureRandom.hex

      content_tag(:div, id: container_id) do
        content_tag(:div, '', data: {
          update_path: plugin('identity').projects_path({
            per_page: (options[:per_page] || 3),
            filter: (options[:filter] || {}),
            partial: true
          }),
          update_immediately: true
        })
      end

    end

    def role_label_long(role_name)
      t("roles.#{role_name}") + " (#{role_name})"
    end

    def wizard_step(options={},&block)
      title = options[:title]
      description = options[:description]
      mandatory = options[:mandatory] || false
      status = options[:status]
      action_button_options = options[:action_button]
      skip_button_options = options[:skip_button]

      if action_button_options
        label = action_button_options[:label] || 'Activate'
        url = action_button_options[:url]
        css_class = 'btn btn-info pull-right'
        if url
          action_button = link_to(label,url, data: {modal: true, wizard_action_button: true}, class: css_class)
        else
          action_button = link_to(label,'javascript:void(0)', class: css_class, disabled: true)
        end
      end

      if skip_button_options
        label = skip_button_options[:label] || 'Do this later'
        url = skip_button_options[:url]
        css_class = 'btn btn-default btn-xs pull-right'
        if url
          skip_button = link_to(label,url, class: css_class)
        else
          skip_button = link_to(label,'javascript:void(0)')
        end
      end

      css_class = case status
      when ProjectProfile::STATUS_DONE then 'success'
      when ProjectProfile::STATUS_SKIPPED then 'warning'
      when 'pending' then 'default'
      else 'info'
      end

      #byebug
      content_tag :div, class: "bs-callout bs-callout-emphasize bs-callout-#{css_class}" do
        content_tag :div, class: 'row' do
          concat(content_tag(:div, class: 'col-md-10') do
            concat content_tag(:h4, title)
            block.call
          end)
          concat(content_tag(:div, class: 'col-md-2') do
            if status==ProjectProfile::STATUS_SKIPPED
              concat(content_tag :span, 'skipped', class: 'pull-right')
              concat(action_button)
            elsif status==ProjectProfile::STATUS_DONE
              content_tag :i, '', class: 'fa fa-check fa-3x pull-right'
            else
              concat(content_tag :p, action_button)
              concat(content_tag :p, skip_button)
            end
          end)
        end
      end

    end

  end
end

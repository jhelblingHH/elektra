module Monitoring
  module ApplicationHelper

    def show_severity(severity)
      styles = {
        'LOW'      => 'text-info',
        'MEDIUM'   => 'text-warning',
        'HIGH'     => 'text-danger',
        'CRITICAL' => 'text-danger',
      }
      return content_tag(:span, severity.capitalize, class: styles.fetch(severity, ''))
    end

    def show_state(state)
      styles = {
        'OK'           => 'text-success',
        'UNDETERMINED' => 'text-warning',
        'ALARM'        => 'text-danger',
      }
      return content_tag(:span, state.capitalize, class: styles.fetch(state, ''))
    end

  end
end

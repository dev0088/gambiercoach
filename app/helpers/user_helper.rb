require 'user_library'

module UserHelper
  include UserLibrary

  # Abstraction to make views a little cleaner
  def form_input(helper_method, prompt, field_name=nil, options = {}, form_name = nil)
    form_name = "user" if form_name.nil?
    case helper_method.to_s
    when 'hidden_field'
      self.hidden_field(form_name, field_name, options)
    when /^.*button$/
      <<-EOL
      <tr><td class="button" colspan="2">
        #{self.send(helper_method, form_name, prompt, options)}
      </td></tr>
      EOL
    else
      field = (
        case helper_method
        when :select
          self.send(helper_method, form_name, field_name, options.delete('values'), options)
        when :password_field
          options[:value] = ""
          self.send(helper_method, form_name, field_name, options)
        else
          self.send(helper_method, form_name, field_name, options)
        end)

<<-EOL
        <tr class="two_columns">
          <td class="prompt"><label>#{prompt}:</label></td>
          <td class="value">#{field}</td>
        </tr>
        EOL
    end
  end

  def title_helper
    "#{params[:controller]} #{params[:action]}"
  end

  def start_form_tag_helper(options = {})
    url = url_for(:action => "#{params[:action]}")
    "#{self.send(:start_form_tag, url, options)}"
  end

  def attributes(hash)
    hash.keys.inject("") { |attrs, key| attrs + %{#{key}="#{h(hash[key])}" } }
  end

  def read_only_field(form_name, field_name, html_options)
    "<span #{attributes(html_options)}>#{instance_variable_get('@' + form_name)[field_name]}</span>"
  end

  def submit_button(form_name, prompt, html_options)
    %{<input name="submit" type="submit" value="#{prompt}" />}
  end

  def changeable(user, field)
    if user.new_record? or [ 'firstname', 'lastname' ].include?(field)
      :text_field
    else
      :read_only_field
    end
  end
end

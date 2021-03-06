use_inline_resources if defined?(use_inline_resources)

def whyrun_supported?
  true
end

action :create do
  templates = new_resource.templates.map { |v| Mash.from_hash(v) }

  case node['consul_template']['init_style']
  when 'runit', 'systemd'
    consul_template_user = node['consul_template']['service_user']
    consul_template_group = node['consul_template']['service_group']
  when 'supervisor'
    consul_template_user = node['consul_template']['service_user']
    consul_template_group = 'root'
  else
    consul_template_user = 'root'
    consul_template_group = 'root'
  end

  # Create entries in configs-template dir but only if it's well formed
  templates.each_with_index do |v, i|
    fail "Missing source for #{i} entry at '#{new_resource.name}" if v[:source].nil?
    fail "Missing destination for #{i} entry at '#{new_resource.name}" if v[:destination].nil?
  end

  # Ensure config directory exists
  directory node['consul_template']['config_dir'] do
    user consul_template_user
    group consul_template_group
    mode 0755
    recursive true
    action :create
  end

  template ::File.join(node['consul_template']['config_dir'], new_resource.name) do
    cookbook 'consul-template'
    source 'config-template.json.erb'
    user consul_template_user
    group consul_template_group
    mode node['consul_template']['template_mode']
    variables(:templates => templates)
    not_if { templates.empty? }
  end
end

action :delete do
  file ::File.join(node['consul_template']['config_dir'], new_resource.name) do
    action :delete
  end
end

alias_method :action_add, :action_create
alias_method :action_remove, :action_delete

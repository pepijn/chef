package "sudo"
package "htop"

admin_user = node[:user][:name]

users = [admin_user, "app"]

users.each do |domain|
  home_dir = "/home/#{domain}"
  name = domain.split('.').first

  user name do
    home home_dir
    supports manage_home: true
  end

  directory home_dir do
    mode 0750
  end
end

### SSH key
ssh_dir = "/home/#{admin_user}/.ssh"
directory ssh_dir do
  mode 0700
  user admin_user
  group admin_user
end

file "#{ssh_dir}/authorized_keys" do
  content node[:user][:key]
  mode 0600
  user admin_user
  group admin_user
end

### SSH server
service "ssh" do
  supports reload: true
end

template "etc/ssh/sshd_config" do
  notifies :reload, "service[ssh]"
end

template "etc/sudoers.d/sudo_pepijn" do
  mode 0440
end

### Nginx
package "nginx"

service "nginx" do
  supports reload: true
end

template "nginx" do
  path "etc/nginx/sites-available/default"
  notifies :reload, "service[nginx]"
end

### Ruby
package "ruby1.9.3"

gem_package "bundler"

### Monit
package "monit"

service "monit" do
  supports restart: true
end

template "etc/monit/conf.d/monit.conf" do
  notifies :restart, "service[monit]"
end

### MySQL
package "mysql-server-5.5"

### Firewall
firewall "ufw" do
  action :enable
end

firewall_rule "ssh" do
  port 22
  action :allow
end

firewall_rule "web" do
  ports [80, 443]
  protocol :tcp
  action :allow
end

### SSL
directory "etc/ssl/private"

%w(key crt).each do |ext|
  template "etc/ssl/private/plict.#{ext}"
end

### Postfix
package "postfix"

### Fail2ban
package "fail2ban"


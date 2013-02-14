package "sudo"
package "htop"
package "ufw"

template "etc/hostname"

admin_user = node[:user][:name]

directory "home" do
  mode 0751
end

users = [admin_user]
users += %w(henryderijk.nl miriamvanderpol.com)
users.each do |domain|
  home_dir = "/home/#{domain}"
  name = domain.split('.').first

  user name do
    home home_dir
    supports manage_home: true
  end

  directory home_dir do
    group "www-data"
    mode 0750
  end

  directory "#{home_dir}/public_html" do
    user name
    group name
  end

  group "clients" do
    members name
    append true
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

### Apache 2
package "apache2"

service "apache2" do
  supports reload: true
end

%w(conf load).each do |extension|
  link "etc/apache2/mods-enabled/userdir.#{extension}" do
    to "../mods-available/userdir.#{extension}"
  end
end

%w(vhost_alias expires rewrite headers).each do |mod|
  link "etc/apache2/mods-enabled/#{mod}.load" do
    to "../mods-available/#{mod}.load"
  end
end

template "apache2" do
  path "etc/apache2/sites-available/default"
  notifies :reload, "service[apache2]"
end

template "etc/apache2/ports.conf" do
  notifies :reload, "service[apache2]"
end

### PHP5
package "libapache2-mod-php5"
package "php5-mysql"
package "libssh2-php"
package "php-apc"
package "php5-curl"

template "etc/apache2/mods-enabled/php5.conf" do
  notifies :reload, "service[apache2]"
end

### PhpMyAdmin
package "phpmyadmin"

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

### FTP
package "vsftpd"

service "vsftpd" do
  supports restart: true
end

template "etc/vsftpd.conf" do
  notifies :restart, "service[vsftpd]"
end

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


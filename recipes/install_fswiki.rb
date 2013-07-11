#
# Cookbook Name:: wiki
# Recipe:: install_fswiki.rb
#
# Copyright 2013, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

include_recipe "fswiki::web"

# fswiki インストールの事前準備
%w{
	perl-CGI unzip
}.each do |package_name|
        package "#{package_name}" do
		action :install
	end
end


# Source ファイルの設置 
cookbook_file "/tmp/wiki3_6_4.zip" do
	source "wiki3_6_4.zip"
	owner "apache"
	group "apache"
	mode "0644"
end


# Source ファイルの展開
script "unzip" do
       interpreter "bash"
       user "apache"
       group "apache"
       cwd "/tmp"
       code <<-EOH
               unzip wiki3_6_4.zip
       EOH
end


# wiki 用 Directory の作成
directory "#{node[:fswiki][:_MAIN_DIRECTORY]}" do
	owner "apache"
	group "apache"
	mode 00755
	recursive true
	action :create
end


# Default のままで利用する Director の準備
%w{
	docs lib plugin theme tmpl setup.dat setup.sh wiki.cgi	
}.each do |default_dir|
	execute "move-directories" do
		command "mv /tmp/wiki3_6_4/#{default_dir} #{node[:fswiki][:_MAIN_DIRECTORY]}"
	end
end


# Backup 取得用の Directory の作成
%w{
	attach config backup data log pdf plugin
}.each do |backup_dir|
	directory "#{node[:fswiki][:_BACKUP_DIRECTORY]}/#{backup_dir}" do
		owner "apache"
		group "apache"
		mode 00755
		recursive true
		action :create
	end
end


# Backup 取得用の Directory の link の作成
%w{
	attach backup log pdf config data
}.each do |link_dir|
	link "#{node[:fswiki][:_MAIN_DIRECTORY]}/#{link_dir}" do
		to "#{node[:fswiki][:_BACKUP_DIRECTORY]}/#{link_dir}"
	end
end


# config/data のファイルの移動
%w{
	config data
}.each do |directory|
	execute "move-directories" do
		command "mv /tmp/wiki3_6_4/#{directory}/* #{node[:fswiki][:_MAIN_DIRECTORY]}/#{directory}"
	end
end


# パッチ Source ファイルの設置 
%w{
	fswiki-patch-20110813.zip fswiki-pache-20110823.zip
}.each do |patch_source|
	cookbook_file "/tmp/#{patch_source}" do
		source "#{patch_source}"
		owner "apache"
		group "apache"
		mode "0644"
	end

	script "unzip_patch_source" do
		interpreter "bash"
		user "apache"
		group "apache"
		cwd "/tmp"
		code <<-EOH
			unzip #{patch_source}
		EOH
	end
end


# patch fswiki-patch-20110813 の適用
execute "fswiki-patch-20110813" do
	command "mv /tmp/fswiki-patch-20110813/lib/Util.pm #{node[:fswiki][:_MAIN_DIRECTORY]}/lib/Util.pm"
end


# patch fswiki-pache-20110823 の適用
execute "fswiki-pache-20110823" do
	command "mv /tmp/fswiki-pache-20110823/lib/Wiki/InterWiki.pm #{node[:fswiki][:_MAIN_DIRECTORY]}/lib/Wiki/InterWiki.pm"
end


# setup スクリプトの実行
execute "execute_setup_script" do
	command "cd #{node[:fswiki][:_MAIN_DIRECTORY]} ; ./setup.sh"
end


# 不要なファイルの削除
%w{
	wiki3_6_4.zip fswiki-pache-20110823.zip fswiki-patch-20110813.zip
}.each do |remove_file|
	file "/tmp/#{remove_file}" do
		action :delete
	end
end


# 不要な Directory の削除
%w{
	wiki3_6_4 fswiki-pache-20110823 fswiki-patch-20110813
}.each do |remove_directory|
	directory "/tmp/#{remove_directory}" do
		recursive true
		action :delete
	end
end

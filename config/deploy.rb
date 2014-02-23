set :application, 'iktas'
set :url, 'http://iktas.me/'

# SCM
set :scm, :git
set :repository, 'git@github.com:dreamlx/iktas_me.git'
set :branch, 'master'

# Server
server '106.187.45.40', :app, :web, :db, primary: true
set :user, 'root'
set :use_sudo, false
set :deploy_to, '/home/ROR/kitas.me'
default_run_options[:pty] = true
ssh_options[:forward_agent] = true

# Database
set :db_password do
  Capistrano::CLI.password_prompt("database password:")
end

# RVM
require "rvm/capistrano"
set :rvm_type, :user

# Bundler
require "bundler/capistrano"

# Whenever
set :whenever_command, "bundle exec whenever"
require "whenever/capistrano"

namespace :deploy do
  # Setup database
  namespace :db do
    desc "Generate database configuration"
    task :setup do
      run "mkdir -p #{File.join(shared_path, 'config')}"
      db_config = <<-EOF
        adapter: mysql2
        encoding: utf8
        reconnect: false
        database: berlin_production
        pool: 5
        username: railsadmin
        password: #{db_password}
        socket: /var/run/mysqld/mysqld.sock
      EOF
      put db_config, File.join(shared_path, 'config', 'database.yml')
    end

    desc "[internal] Updates the symlink for database.yml file to the just deployed release."
    task :create_symlink, :except => { :no_release => true } do
      run "ln -nfs #{File.join(shared_path, 'config', 'database.yml')} #{File.join(release_path, 'config', 'database.yml')}"
    end
  end
  after "deploy:setup", "deploy:db:setup" unless fetch(:skip_db_setup, false)
  after "deploy:create_symlink", "deploy:db:create_symlink"
  after "deploy:update", "deploy:migrate"

  # Restart Passenger
  task :start do ; end
  task :stop do ; end
  task :restart, roles: :app, except: { no_release: true } do
    run "#{try_sudo} touch #{File.join(current_path, 'tmp', 'restart.txt')}"
  end

  task :warm_up do
    run "curl --silent #{url} > /dev/null" if fetch(:url, false)
  end
  after "deploy:restart", "deploy:warm_up"

  namespace :carrierwave do
    desc "Create symlink"
    task :create_symlink, :except => { :no_release => true } do
      run "mkdir -p #{File.join(shared_path, 'uploads')}"
      run "ln -nfs #{File.join(shared_path, 'uploads')} #{File.join(release_path, 'public', 'uploads')}"
    end
    after "deploy:create_symlink", "deploy:carrierwave:create_symlink"
  end

  namespace :custom_configuration do
    desc "Generate configuration"
    task :setup do
      run "mkdir -p #{File.join(shared_path, 'config')}"
      run "touch #{File.join(shared_path, 'config', 'application.yml')}"
    end

    desc "Create symlink"
    task :create_symlink, :except => { :no_release => true } do
      #run "rm #{File.join(current_path, 'config', 'application.yml')}"
      run "ln -nfs #{File.join(shared_path, 'config', 'application.yml')} #{File.join(release_path, 'config', 'application.yml')}"
    end
    after "deploy:setup", "deploy:custom_configuration:setup" unless fetch(:skip_db_setup, false)
    after "deploy:create_symlink", "deploy:custom_configuration:create_symlink"
  end
end

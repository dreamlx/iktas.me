require 'rvm/capistrano' # 支持rvm
require 'bundler/capistrano'  # 支持自动bundler
set :rvm_autolibs_flag, "read-only"        # more info: rvm help autolibs

set :application, "iktas" #应用的名字
set :keep_releases, 10 
set :location, "106.187.45.40" #部署的ip地址
# set :location, "http://tangdigital.com/"
role :web, location                       # Your HTTP server, Apache/etc
role :app, location                       # This may be the same as your `Web` server
role :db,  location, :primary => true # This is where Rails migrations will run
#role :db,  "3dtzk.com"

#server details
default_run_options[:pty] = true  # Must be set for the password prompt
set :deploy_to, "/srv/www/iktas.me"  #部署在服务器上的地址

set :user, "root" #ssh连接服务器的帐号
# set :use_sudo, false    #comment it because using root to login
set :ssh_options, { :forward_agent => true }
#repo details
set :scm, :git
# Or: `accurev`, `bzr`, `cvs`, `darcs`, `git`, `mercurial`, `perforce`, `subversion` or `none`
set :scm_username, ENV["GITHUB_USERNAME"] #github帐号
set :scm_passphrase, ENV["GITHUB_PASSWORD"] #设置github  ssh时设置到密码
set :repository,  "git@github.com:dreamlx/iktas.me.git" #项目在github上的帐号
set :branch, "master" #github上具体的分支
set :deploy_via, :remote_cache

before 'deploy:setup', 'rvm:install_rvm'

#tasks
namespace :deploy do
  desc "SCP transfer figaro configuration to the shared folder"

  task :restart, :roles => :app do
    run "touch #{current_path}/tmp/restart.txt"    
  end

  task :stop, :roles => :app do
      #do nonthing
  end

  desc "Symlink shared resources on each release - not used"
  task :symlink_shared, :roles => :app do    
  end

  task :precompile, :roles => :web do  
    run "cd #{current_path} && #{rake} RAILS_ENV=production assets:precompile"  
  end

  # https://gist.github.com/meskyanichi/157958
  namespace :db do
    desc "Moves the SQLite3 Production Database to the shared path"
    task :move_to_shared do
      puts "\n\n=== Moving the SQLite3 Production Database to the shared path! ===\n\n"
      run "mv #{current_path}/db/production.sqlite3 #{shared_path}/db/production.sqlite3"
      system "cap deploy:setup_symlinks"
      system "cap deploy:set_permissions"
    end
  end
end



after "deploy:update", "deploy:symlink_shared" 
after "deploy:update", "deploy:migrate"
after "deploy:migrate", "deploy:precompile"

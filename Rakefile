require "bundler"
Bundler.setup
Bundler::GemHelper.install_tasks

require 'rspec'
require 'rspec/core/rake_task'

desc "Run all examples"
RSpec::Core::RakeTask.new(:spec) do |t|
  # t.ruby_opts = %w[-w -c]
end

desc 'Set up the rails app that the specs and features use'
task :testbed => 'testbed:rebuild'

namespace :testbed do
  desc 'Generate a minimal surveyor-using rails app'
  task :generate do
    Tempfile.open('surveyor_Rakefile') do |f|
      f.write("application \"config.time_zone='Rome'\"");f.flush
      sh "bundle exec rails new testbed --database=postgresql --skip-bundle -m #{f.path}" # don't run bundle install until the Gemfile modifications
    end
    chdir('testbed') do
      gem_file_contents = File.read('Gemfile')
      gem_file_contents.sub!(/^(gem 'rails'.*)$/, %Q{# \\1\nplugin_root = File.expand_path('../..', __FILE__)\neval(File.read File.join(plugin_root, 'Gemfile.rails_version'))\ngem 'surveyor_warehouse', :path => plugin_root})
      File.open('Gemfile', 'w'){|f| f.write(gem_file_contents) }

      Bundler.with_clean_env do
        sh 'bundle install' # run bundle install after Gemfile modifications
      end
    end
  end

  desc 'Prepare the databases for the testbed'
  task :migrate do
    chdir('testbed') do
      Bundler.with_clean_env do
        sh 'bundle exec rails generate surveyor:install'
        sh 'bundle exec rake db:drop db:create db:migrate db:test:prepare'
      end
    end
  end

  desc 'Remove the testbed entirely'
  task :remove do
    rm_rf 'testbed'
  end

  task :rebuild => [:remove, :generate, :migrate]

  desc 'Load all the sample surveys into the testbed instance'
  task :surveys do
    cd('testbed') do
      Dir[File.join('surveys', '*.rb')].each do |fn|
        puts "Installing #{fn} into the testbed"
        system("rake surveyor FILE='#{fn}'")
      end
    end
  end
end

task :spec => 'testbed'


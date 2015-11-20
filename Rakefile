#!/usr/bin/env rake

require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task :ci => [:dump, :install, :test]

task :default => :spec

task :dump do
  sh 'vim --version'
end

task :test    => :spec

task :spec do
    sh "rspec ~/.vim-flavor/repos/LucHermitte_vim-UT/spec"
end

task :install do
  sh 'cd tests && bundle exec vim-flavor install'
end


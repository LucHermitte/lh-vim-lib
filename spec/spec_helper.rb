require 'tmpdir'
require 'vimrunner'
require 'vimrunner/rspec'
require_relative './support/vim'
require 'rspec/expectations'
# require 'simplecov'

# SimpleCov.start

RSpec::Matchers.define :be_successful do
  match do |actual|
    actual[1].empty? or expect(actual[0]).to eq 1
  end
  failure_message do |actual|
    # pp actual
    # pp actual[1].empty?
    actual[1].join("\n")
  end
end

Vimrunner::RSpec.configure do |config|
  config.reuse_server = true

  vim_plugin_path = File.expand_path('.')
  vim_flavor_path   = ENV['HOME']+'/.vim/flavors'

  config.start_vim do
    vim = Vimrunner.start_gvim
    # vim = Vimrunner.start_vim
    # LetIfUndef
    # vim_lib_path      = File.expand_path('../../../lh-vim-lib', __FILE__)
    vim.append_runtimepath(vim_plugin_path)

    vim.add_plugin(vim_flavor_path, 'bootstrap.vim')
    vim_UT_path      = File.expand_path('../../../vim-UT', __FILE__)
    vim.add_plugin(vim_UT_path, 'plugin/UT.vim')

    pp vim_flavor_path
    pp vim.echo('&rtp')

    vim
  end
end

RSpec.configure do |config|
  config.include Support::Vim

  def write_file(filename, contents)
    dirname = File.dirname(filename)
    FileUtils.mkdir_p dirname if not File.directory?(dirname)

    File.open(filename, 'w') { |f| f.write(contents) }
  end

  # Execute each example in its own temporary directory that is automatically
  # destroyed after every run.
  config.around do |example|
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        example.call
      end
    end
  end
end

# vim:set sw=2:

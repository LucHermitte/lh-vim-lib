# encoding: UTF-8
require 'spec_helper'
require 'pp'

RSpec.describe "autoload/lh/map.vim" do
  # after(:all) do
    # vim.kill
  # end

  describe "Dependent plugins are available" do
      it "Has vim-UT" do
          expect(vim.echo('&rtp')).to match(/vim-UT/)
          expect(vim.command("scriptnames")).to match(/plugin.UT\.vim/)
      end
  end

  describe "Run all tests" do
      files = Dir.glob('./tests/lh/*.vim')
      files.each{ |file|
          it "Run [#{file}]" do
              # expect(vim.echo('lh#UT#run("", "'+file+'")')).to match(/1$/)
              result = vim.echo('lh#UT#run("", "'+file+'")')
              # Keep only the list
              result = result.match(/\[\d,.*\]\]/)[0]
              expect(eval(result)).to be_successful
          end
      }
  end


end

# vim:set sw=2:


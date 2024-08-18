# encoding: UTF-8
#
# unit tests spec runner dedicated to lh-vim-lib
# -> These tests needs to rely 100% on clones lh-vim-lib

require 'pp'

RSpec.describe "unit tests" do
  # First search for a vimrc that bootstraps vim-flavor v2
  # (v3 uses global packadd from vim8)
  # It could be:
  # - either {plugin}/spec/flavor.vimrc
  # - or ~/.vimrc/flavors/bootstrap.vim
  vimrc_candidates = ['spec/flavor.vimrc',
                      ENV['HOME']+'/.vim/flavors/bootstrap.vim',
                      ENV['HOME']+'/vimfiles/flavors/bootstrap.vim']
  vimrc = vimrc_candidates.find{ |candidate| File.file?(candidate)}
  if vimrc.nil?
    print "no bootstrapping vimrc found...\n"
    u_vimrc = ""
  else
    print "bootstrapping vimrc found: #{vimrc}\n"
    vim_plugin_path = File.expand_path('.')
    # '-u {file}' forces '&compatible' => '-N'
    u_vimrc = "-u #{vimrc} -N --cmd 'set rtp+=#{vim_plugin_path},#{vim_plugin_path}/after' --cmd 'filetype plugin on'"
  end

  cmd = %(vim #{u_vimrc} -X -V1 -e -s -c "echo 'RTP: '..&rtp" -c "q")
  pp system(cmd)

  # The tests
  describe "Check all tests", :unit_tests => true do
    pwd = Dir.pwd
    files = Dir.glob('./tests/**/*.vim')
    pp "In directory #{pwd}, run #{files}"
    files.each{ |file|
      it "[#{file}] runs fine" do
        abs_file = pwd + '/' + file
        log_file = abs_file + '.log'
        # pp "file: #{file}"
        # pp "abs: #{abs_file}"
        # pp "log: #{log_file}"
        # TODO: collect verbose mode messages
        cmd = %(vim #{u_vimrc} -V1 -e -s -c "UTBatch #{log_file} #{abs_file}")
        pp cmd
        ok = system(cmd)
        # print "Check log file '#{log_file}' exists\n"
        # expect(log_file).to be_an_existing_file
        if ! ok
          # print "Log file: #{file}.log\n"
          if File.file?(log_file)
            log = File.read(log_file)
          else
            log = "Warning: Cannot read #{log_file}"
          end
        end
        expect(ok).to be_truthy, "expected test to succeed, got\n#{log}\n"
        ### log_file = '/tmp/'+ file + '.log'
        ##vim.command('call writefile(["test"], "'+log_file+'")')
        ##vim.command('call lh#log#set_logger("file", "'+log_file+'")')
        ##vim.command('call lh#log#this("Logging UT '+file+'")')
        ### print "Check log file '#{log_file}' exists\n"
        ##expect(log_file).to be_an_existing_file
        ##result = vim.echo('lh#UT#check(0, "'+abs_file+'")')
        ### pp "result: #{abs_file} -> #{result}"
        ### Keep only the list =>
        ##if not (result.nil? or result.empty?)
        ##    # Clean echoed messages
        ##    result = eval(result.match(/\[\d,.*\]\]/)[0])
        ##end
        ### pp "result0: #{result[0]}"
        ##if result.nil? or result.empty? or (result[0] == 0)
        ##    print "Log file: #{file}.log"
        ##    if File.file?(log_file)
        ##        log = File.read(log_file)
        ##        print "LOG: #{log}\n"
        ##    else
        ##        print "Warning: Cannot read #{log_file}\n"
        ##    end
        ##end
        ##expect(result).to_not be_nil
        ##expect(result).to be_successful
      end
    }
  end
end

# vim:set sw=2:

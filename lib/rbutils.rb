# = RbUtils -- Ruby Utility to get classes, methods, class hierarchy, libraries
#
# rbutils.rb -
# Author:: kyoendo

#require "find"
module RbUtils
  def self.classes
    klasses = constants_plus.map{ |const| eval(const.to_s) }.select{ |k| k.class == Class }
    klasses << Enumerable::Enumerator if RUBY_VERSION == '1.8.7'
    klasses
  end
  
  def self.modules
    constants_plus.map{ |const| eval(const.to_s) }.select{ |m| m.class == Module }
  end
  
  def self.constants
    Module.constants.map{ |c| c.to_s }.select{ |c| eval(c).class.to_s !~ /Class|Module/ }
  end
  
  # depends on library paths
  def self.standard_library
    lib186 = %w(abbrev base64 benchmark bigdecimal cgi cgi-lib complex csv curses date date2 dbm debug delegate digest dl drb e2mmap English enumerator Env erb eregex etc expect fcntl fileutils finalize find forwardable ftools gdbm generator getoptlong getopts gserver iconv importenv io/nonblock io/wait ipaddr irb jcode kconv logger mailread mathn matrix md5 mkmf monitor mutex_m net/ftp net/ftptls net/http net/https net/imap net/pop net/protocol net/smtp net/telnet net/telnets nkf observer open3 open-uri openssl optparse ostruct parsearg parsedate pathname ping pp prettyprint profile profiler pstore pty racc/parser rational rbconfig readbytes readline resolv resolv-replace rexml rinda/rinda rinda/tuplespace rss rubyunit scanf sdbm set sha1 shell shellwords singleton soap socket stringio strscan sync syslog tempfile test/unit thread thwait time timeout tk tmpdir tracer tsort un uri weakref webrick win32/registry win32/resolv Win32API win32ole wsdl xmlrpc xsd yaml zlib)
    lib187 = lib186 - ['securerandom'] + ['enumerator']
    lib191 = lib187 - %w(Env cgi-lib complex date2 eregex finalize ftools generator getopts importenv jcode mailread md5 net/ftptls net/telnets parsearg parsedate ping rational readbytes rubyunit sha1 soap wsdl xsd) + %w(cmath continuation coverage fiber json minitest/mock minitest/spec minitest/unit prime rake ripper rubygems ubygems)
    lib192 = lib191 + ['objspace']
    lib193 = lib192 + ['io/console']

    case RUBY_VERSION
    when '1.8.6' then lib186
    when '1.8.7' then lib187
    when '1.9.1' then lib191
    when '1.9.2' then lib192
    when '1.9.3' then lib193
    end.sort
  end
  
  RUBY186 = "~/.rbenv/versions/1.8.6-p420/bin/ruby"

  def self.ruby186_methods
    begin
      return [] unless system("#{RUBY186} -v")

      meths = %x(#{RUBY186} -rrbutils -e "#{<<CODE}")
        meths = {}
        klass_and_module = RbUtils.classes + RbUtils.modules - [RbUtils]
        klass_and_module.each do |klass|
          meths[klass.to_s] = klass.methods_by_type
        end
        p meths
CODE
      eval(meths)
    rescue Exception => e
    end
  end
  
  private
  def self.constants_plus
    Module.constants + [File::Constants, File::Stat, Process::GID, Process::Status, Process::Sys, Process::UID, Struct::Tms]
  end
end

class Module
  def hierarchy
    (self.superclass ? self.superclass.hierarchy : []).unshift(self)
  end
  
  def methods_by_type(*args)
    meths = {}
    args = ['pu','pt','pr','pui','pti','pri'] if args.empty?
    meth_types = {'pu' => 'public_methods', 'pt' => 'protected_methods', 'pr' => 'private_methods', 'pui' => 'public_instance_methods', 'pti' => 'protected_instance_methods', 'pri' => 'private_instance_methods'}
    args.map!{ |arg| meth_types[arg] }.compact!
    args.each do |mtype|
      meths[mtype] = self.send(mtype, false)
      #match with string or symbol
      meths[mtype].reject!{ |m| m =~ /hierarchy|methods_by_type|class_tree/ }
    end
    meths
  end
end
class Array
  def class_tree(parents)
    result = []
    parents.each do |parent|
      s_class = select{ |this| this.superclass == parent }
      result << (parents.empty? ? [] : class_tree(s_class.reverse)) << parent
    end
    result
  end
end

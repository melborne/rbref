# = RbUtils -- Ruby Utility to get classes, methods, class hierarchy, libraries
#
# rbutils.rb -
# Author:: kyoendo

$added_methods = %w(hierarchy methods_by_type class_tree)

class Module
  def hierarchy
    (self.superclass ? self.superclass.hierarchy : []).unshift(self)
  end
  
  def methods_by_type(mtypes=%w(public_methods protected_methods private_methods public_instance_methods protected_instance_methods private_instance_methods))
    mtypes.inject({}) do |h, mtype|
      h[mtype] = self.send(mtype, false).reject{ |m| $added_methods.include? m.to_s }
      h
    end
  end
end

class Array
  def class_tree(parents)
    parents.inject([]) do |result, parent|
      s_class = select { |this| this.superclass == parent }
      result << (parents.empty? ? [] : class_tree(s_class.reverse)) << parent
      result
    end
  end
end

module RbUtils
  LIB186 = %w(abbrev base64 benchmark bigdecimal cgi cgi-lib complex csv curses date date2 dbm debug delegate digest dl drb e2mmap English Env erb eregex etc expect fcntl fileutils finalize find forwardable ftools gdbm generator getoptlong getopts gserver iconv importenv io/nonblock io/wait ipaddr irb jcode kconv logger mailread mathn matrix md5 mkmf monitor mutex_m net/ftp net/ftptls net/http net/https net/imap net/pop net/protocol net/smtp net/telnet net/telnets nkf observer open3 open-uri openssl optparse ostruct parsearg parsedate pathname ping pp prettyprint profile profiler pstore pty racc/parser rational rbconfig readbytes readline resolv resolv-replace rexml rinda/rinda rinda/tuplespace rss rubyunit scanf sdbm set sha1 shell shellwords singleton soap socket stringio strscan sync syslog tempfile test/unit thread thwait time timeout tk tmpdir tracer tsort un uri weakref webrick win32/registry win32/resolv Win32API win32ole wsdl xmlrpc xsd yaml zlib)
  LIB187 = LIB186 - ['securerandom']
  LIB191 = LIB187 - %w(Env cgi-lib complex date2 eregex finalize ftools generator getopts importenv jcode mailread md5 net/ftptls net/telnets parsearg parsedate ping rational readbytes rubyunit sha1 soap wsdl xsd) + %w(cmath continuation coverage fiber json minitest/mock minitest/spec minitest/unit prime rake ripper rubygems ubygems)
  LIB192 = LIB191 + ['objspace']
  LIB193 = LIB192 + ['io/console']
  LIB200 = LIB193 - ['kconv', 'syck']
  LIB210 = LIB200 - ['curses']

  class << self
    def classes
      arr = []
      ObjectSpace.each_object(Class){ |obj| arr << obj }
      arr
    end

    def modules
      arr = []
      ObjectSpace.each_object(Module){ |obj| arr << obj }
      arr - classes
    end

    def all_constants
      Module.constants.reject{ |c| [Class, Module].include? eval("#{c}").class } - constants
    end

    # depends on library paths
    def standard_libraries
      case RUBY_VERSION
      when '1.8.6' then LIB186
      when '1.8.7' then LIB187
      when '1.9.1' then LIB191
      when '1.9.2' then LIB192
      when '1.9.3' then LIB193
      when '2.0.0' then LIB200
      when '2.1.0' then LIB210
      else
        abort "Not found Starndard Library Info"
      end.sort
    end

    def methods_in_previous_ruby
      ruby =
        case RUBY_VERSION
        when /^2/ then '1.9.3-p327'
        else '1.8.6-p420'
        end
      ruby_path = "~/.rbenv/versions/#{ruby}/bin/ruby"

      begin
        return [] unless system("#{ruby_path} -v")

        meths = %x(#{ruby_path} -rrbutils -e "#{<<CODE}")
          h = {}
          objects = []
          ObjectSpace.each_object(Module) { |obj| objects << obj }
          objects -= [RbUtils]
          objects.each do |klass|
            h[klass.to_s] = klass.methods_by_type
          end
          p h
CODE
        eval(meths)
      rescue => e
        print "class => #{e.class}\nmessage => #{e.message}\nbacktrace => #{e.backtrace}\n"
      end
    end
  end
end

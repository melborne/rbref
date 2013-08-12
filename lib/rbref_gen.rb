#!/usr/bin/env ruby
# generate Ruby Reference Index
# usage: ruby186 rbref_gen.rb

$:.unshift(File.dirname(__FILE__))
require "rbutils"
require "erb"

class RbrefGenerator
  RUBY_REF = "http://doc.ruby-lang.org/ja/#{RUBY_VERSION}/"
  DIRECT_LINKS = 
    { "Standard Library" => "#{RUBY_REF}library",
      "Regular Expression" => "#{RUBY_REF}doc/spec=2fregexp.html",
      "sprintf format" => "#{RUBY_REF}doc/print_format.html",
      "strftime format" => "#{RUBY_REF}method/Time/i/strftime.html",
      "Kernel module" => "#{RUBY_REF}class/Kernel.html",
      "M17N" => "#{RUBY_REF}doc/spec=2fm17n.html",
    }
  SITES =
    { "RubyGems" => "http://rubygems.org/",
      "The Ruby Toolbox" => "https://www.ruby-toolbox.com/",
      "Gem Docs" => "http://rubydoc.info/gems",
      "Ruby Official" => "http://www.ruby-lang.org/ja/",
      "Rubyist Magazine" => "http://jp.rubyist.net/magazine/",
      "Ruby-list" => "http://blade.nagaokaut.ac.jp/ruby/ruby-list/index.shtml",
      "Ruby-talk" => "http://blade.nagaokaut.ac.jp/ruby/ruby-talk/index.shtml",
      "RHG" => "http://i.loveruby.net/ja/rhg/book/"
     }
  RUBY_DESC = 
    if RUBY_VERSION >= '1.8.7'
      RUBY_DESCRIPTION
    else
      "ruby #{RUBY_VERSION} (#{RUBY_RELEASE_DATE} patchlevel #{RUBY_PATCHLEVEL}) [#{RUBY_PLATFORM}]"
    end
  ENCODE_TBL = { "*" => "=2a", "+" => "=2b", "\\-" => "=2d", "." => "=2e", "/" => "=2f", ":" => "=3a", "<" => "=3c", "=" => "=3d", ">" => "=3e", "?" => "=3f", "\\[" => "=5b", "\\]" => "=5d", "\\^" => "=5e", "~" => "=7e", "|" => "=7c", "@" => "=40", "!" => "=21",  "%" => "=25", "&" => "=26"}
  
  REQUIRED_HERE = [:ERB, :CGI, :StringScanner, :Gem, :RbConfig, :RbUtils, :RbrefGenerator]
  
  def self.method_added(name)
    @@methods_here ||= []
    @@methods_here << name
  end
  
  def get_classes_and_error_classes
    klasses = RbUtils.classes.reject { |klass| REQUIRED_HERE.any? { |ex| klass.to_s.match /^#{ex}/ } }.sort_by { |klass| klass.to_s }
    klasses, errors = klasses.partition { |klass| klass.to_s !~ /Error|Exception|Interrupt|fatal/}
    root = self.class.ancestors.select { |anc| anc.class == Class }.last
    klasses = klasses.class_tree([root])
    errors = errors.class_tree([Exception])
    return [klasses, errors].map { |tree| tree.flatten.reverse }
  end
  
  def get_modules
    modules = RbUtils.modules.sort_by{ |k| k.to_s }.reject { |mod| REQUIRED_HERE.any? { |ex| mod.to_s.match /^#{ex}/ }}.sort_by { |mod| mod.to_s }
  end
  
  def get_constants
    (RbUtils.all_constants - self.class.constants).sort
  end
  
  def get_libraries
    RbUtils.standard_libraries
  end
  
  def pre_ruby_methods
    RbUtils.methods_in_previous_ruby
  end
  
  def generate(path="../views/#{RUBY_VERSION.delete('.')}.erb")
    File.open(path, "w") do |f|
      f.puts ERB.new(DATA.read).result
    end
  end
  
  def method_list(klass)
    methods = klass.methods_by_type
    methods.keys.each do |key|
      unless klass == Module && key == 'private_instance_methods'
        methods[key].reject!{ |m| @@methods_here.include? m }
      end
    end
    return methods.reject{ |k,v| v.empty? }
  end
  
  def class_link(klass)
    begin
      unless PRE_RUBY_METHODS.keys.to_s.include?(klass.to_s)
        'class19_link'
      else
        'top_class_link'
      end
    rescue Exception => e
      'class19_link'
    end
  end
  
  def method_link(klass, meth_type, meth)
    begin
      unless PRE_RUBY_METHODS[klass.to_s][meth_type].map(&:to_s).include?(meth.to_s)
        'meth19_link'
      else
        "meth_link"
      end
    rescue Exception => e
      "meth19_link"
    end
  end
  
  def h(url)
    url = url.to_s.sub(/\.class$/, '') # handle errgular link for ARGF.class
    url.gsub(/["#{ENCODE_TBL.keys.join}"]/) do |s|
      s.sub!(/[\[\]\^\-]/) { |i| "\\#{i}" }
      ENCODE_TBL[s]
    end
  end
  
  def ruby_man_method_link(klass, meth_type, meth)
    case
    when klass == Kernel && meth_type == "public_instance_methods"
      klass = Object
      mtype = "i"
    when klass.class == Module
      if meth_type !~ /instance/
        klass = Module
        mtype = "i"
      elsif meth_type == 'private_instance_methods'
        mtype = "m"
      else #'public_instance_methods'
        mtype = "i"
      end
    when meth_type == 'public_methods'
      if meth =~ /allocate|new|superclass/
        klass = Class
        mtype = "i"
      else
        mtype = "s"
      end
    when meth_type =~ /private/
      klass = Object unless klass == Module
      mtype = "i"
    when klass == ARGF.class
      klass = ARGF
      mtype = "s"
    else # public_instance_methods
      mtype = "i"
    end
    RUBY_REF + "method/#{h klass}" + "/#{mtype}/#{h meth}.html"
  end
  
end

rb = RbrefGenerator.new

klasses, error_klasses = rb.get_classes_and_error_classes
modules = rb.get_modules
klass_and_module = klasses + modules + error_klasses
error_klasses << 'fatal'
constants = rb.get_constants
libraries = rb.get_libraries
PRE_RUBY_METHODS = rb.pre_ruby_methods
RUBY_REF = RbrefGenerator::RUBY_REF
RUBY_DESC = RbrefGenerator::RUBY_DESC
DIRECT_LINKS = RbrefGenerator::DIRECT_LINKS
SITES = RbrefGenerator::SITES

rb.generate()

__END__
 <div id='top'>
   <h2 id="ruby_title">
     <a id="top_title_link" href="<%= RUBY_REF %>doc/index.html"> <%= RUBY_DESC.capitalize %></a>
   </h2>
 </div>
 <div class='top_list'>
   <h3 class='top_subtitle'>Class</h3>
   <% klasses.each do |klass| %>
   <span><a class=<%= rb.class_link(klass) %> href="#<%= klass %>"><%= klass %></a> | </span>
   <% end %>
   <span class="counter"><%= klasses.length %></span>
 </div>
 <div class='top_list'>
   <h3 class='top_subtitle'>Module</h3>
   <% modules.each do |mod| %>
   <span><a class=<%= rb.class_link(mod) %> href="#<%= mod %>"><%= mod %></a> | </span>
   <% end %>
   <span class="counter"><%= modules.length %></span>
 </div>
 <div class='top_list'>
   <h3 class='top_subtitle'>Exception Class</h3>	    
   <% error_klasses.each do |error| %>
     <% if error != 'fatal' %>
       <span><a class=<%= rb.class_link(error) %> href="#<%= error %>"><%= error %></a> | </span>
     <% else %>
       <span><a class=<%= rb.class_link(error) %> href="<%= RUBY_REF %>class/fatal.html"><%= error %></a> | </span>
     <% end %>
   <% end %>
   <span class="counter"><%= error_klasses.length %></span>
 </div>
 <div class='top_list'>
   <h3 class='top_subtitle'>Standard Library</h3>	    
   <% libraries.each do |lib| %>
   <span><a class="top_class_link" href="<%= RUBY_REF %>library/<%= rb.h(lib) %>.html"><%= lib %></a> | </span>
   <% end %>
   <span class="counter"><%= libraries.length %></span>
 </div>
 <div class='top_list'>
   <h3 class='top_subtitle'>Direct Links</h3>	    
   <% DIRECT_LINKS.each do |name, site| %>
   <span><a class="top_class_link" href=<%= site %>><%= name %></a> | </span>
   <% end %>
 </div>
 <div class='top_list'>
   <h3 class='top_subtitle'>Sites</h3>	    
   <% SITES.each do |name, site| %>
   <span><a class="top_class_link" href=<%= site %>><%= name %></a> | </span>
   <% end %>
 </div>
 
 <% klass_and_module.each do |klass| %>
   <% super_classes = klass.class == Class ? klass.hierarchy-[klass] : [klass.class] %>
   <% if RUBY_VERSION >= '1.9' %>
 	  <% super_classes -= [BasicObject] unless klass == Object %>
   <% end %>
   <% mod = klass.included_modules %>
   <span id="top_link">
     <a href="">top</a>
   </span>
   <div class='class_title_bar' id="<%= klass %>">
     <a class="class_link" id='class_name' href="<%= RUBY_REF %>class/<%= rb.h(klass) %>.html"><%= klass %></a><span id='class_suffix'> <%= klass.class %></span>
     <span class="superclass">
       <% unless super_classes.empty? %>
         <% super_classes.each do |sc| %>
           <span>< </span><a class="class_link" href="#<%= sc %>"><%= sc %></a>
         <% end %>
       <% end %>
       <span>
         <% unless mod.empty? %>
           <span>[</span><% mod.each do |m| %>
             <a class='class_link' href='#<%= m %>'><%= m %> </a>
           <% end %><span>]</span>
         <% end %>
       </span>
     </span>
   </div>
 
   <div class='meths'>
     <% rb.method_list(klass).each do |meth_type, meths| %>
       <h3 class='meth_type'><%= meth_type %></h3>
       <% meths.sort.each_with_index do |meth, i| %>
         <span>
           <a class=<%= rb.method_link(klass,meth_type,meth) %> href=<%= rb.ruby_man_method_link(klass,meth_type,meth) %>><%= meth %></a>
           <%= i+1 < meths.length ? " | " : "" %>
         </span>
       <% end %>
       <% if meths.length >= 10 %>
 		    <span class="counter"> | <%= meths.length %></span>
 	    <% end  %>
     <% end %>
     <% if klass == Kernel %>
 		  <h3 class='meth_type'>Constants</h3>
 		  <% constants.each do |const| %>
   			<span><a class='meth_link' href="<%= RUBY_REF %>method/Kernel/c/<%= const %>.html"><%= const %></a> | </span>
   		<% end %>
 		<% end %>
   </div>
 <% end %>

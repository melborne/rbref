# generate Ruby Reference Index
# usage: ruby186 rbref_gen.rb

$:.unshift(File.dirname(__FILE__))
require "rbutils"
require "erb"

RUBY_REF = "http://doc.okkez.net/#{RUBY_VERSION.delete('.')}/view/"
USEFUL_LINKS = 
  { "Standard Library" => "#{RUBY_REF}library",
    "Regular Expression" => "#{RUBY_REF}spec/regexp",
    "M17N" => "#{RUBY_REF}spec/m17n",
    "Ruby Official" => "http://www.ruby-lang.org/ja/",
    "RubyGems" => "http://rubygems.org/",
    "RAA" => "http://raa.ruby-lang.org/",
    "Rubyist Magazine" => "http://jp.rubyist.net/magazine/",
    "Ruby-list" => "http://blade.nagaokaut.ac.jp/ruby/ruby-list/index.shtml",
    "Ruby-talk" => "http://blade.nagaokaut.ac.jp/ruby/ruby-talk/index.shtml",
    "old Ruby Ref" => "http://www.ruby-lang.org/ja/man/html/",
    "RHG" => "http://i.loveruby.net/ja/rhg/book/"
   }
RUBY_DESC = 
  if RUBY_VERSION >= '1.8.7'
    RUBY_DESCRIPTION
  else
    "ruby #{RUBY_VERSION} (#{RUBY_RELEASE_DATE} patchlevel #{RUBY_PATCHLEVEL}) [#{RUBY_PLATFORM}]"
  end

def Object.method_added(name)
  @@methods_here ||= ['method_added']
  @@methods_here << name
end

def method_list(klass)
  methods = klass.methods_by_type
  methods.keys.each do |key|
    unless klass == Module && key == 'private_instance_methods'
      methods[key].reject!{ |m| m =~ /#{@@methods_here.join('|')}/}
    end
  end
  return methods.reject{ |k,v| v.empty? }
end

def class_link(klass)
  begin
    unless RUBY186_METHODS.keys.to_s.include?(klass.to_s)
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
    unless RUBY186_METHODS[klass.to_s][meth_type].include?(meth.to_s)
      'meth19_link'
    else
      "meth_link"
    end
  rescue Exception => e
    "meth19_link"
  end
end

# correct links for Enumerator Class
def enum_class_check(klass)
  if klass.to_s =~ /Enumerator/ and RUBY_VERSION <= "1.9.0"
    'Enumerable=Enumerator'
  else
    klass
  end
end

def ruby_man_method_link(klass, meth_type, meth)
  end_symbol = { "*" => "=2a", "+" => "=2b", "\\-" => "=2d", "/" => "=2f", "<" => "=3c", "=" => "=3d", ">" => "=3e", "?" => "=3f", "\\[" => "=5b", "\\]" => "=5d", "\\^" => "=5e", "~" => "=7e", "|" => "=7c", "@" => "=40", "!" => "=21",  "%" => "=25", "&" => "=26" }
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
  else # public_instance_methods
    mtype = "i"
  end
  meth = meth.to_s.gsub(/["#{end_symbol.keys.join}"]/) do |s|
    s.sub!(/[\[\]\^\-]/) { |i| "\\#{i}" }
    end_symbol[s]
  end
  RUBY_REF + "method/#{enum_class_check(klass)}" + "/#{mtype}/#{meth}"
end

REQUIRED_CLASSES = [ERB, RbUtils]
DEFINED_HERE = ['RUBY_REF','RUBY186_METHODS','RUBY_DESC','USEFUL_LINKS']
def get_classes
  klasses = RbUtils.classes.sort_by{|k| k.to_s } - REQUIRED_CLASSES
  if RUBY_VERSION >= "1.9.0"
    klasses -= [Complex, RubyVM]
    sclass = BasicObject
  else
    klasses -= [StringScanner, StringScanner::Error]
    sclass = Object
  end
  klasses, errors = klasses.partition{|k| k.to_s !~ /Error/}
  klasses = klasses.class_tree([sclass])
  errors = errors.class_tree([Exception])
  return [klasses, errors].map { |tree| tree.flatten.reverse }
end

def get_modules
  modules = RbUtils.modules.sort_by{ |k| k.to_s } - REQUIRED_CLASSES
  modules -= RUBY_VERSION >= "1.9.0" ? [Gem] : []
end

def get_constants
  RbUtils.constants - DEFINED_HERE
end

def get_libraries
  RbUtils.standard_library
end

def get_ruby186_methods
  RbUtils.ruby186_methods
end

def generate(path="../views/#{RUBY_VERSION.delete('.')}.erb")
  File.open(path, "w") do |f|
    f.puts ERB.new(DATA.read).result
  end
end

klasses, error_klasses = get_classes
modules = get_modules
klass_and_module = klasses + modules + error_klasses
constants = get_constants
libraries = get_libraries
RUBY186_METHODS = get_ruby186_methods


generate()

__END__
 <div id='top'>
   <h2 id="ruby_title">
     <a id="top_title_link" href="<%= RUBY_REF %>index"> <%= RUBY_DESC.capitalize %></a>
   </h2>
 </div>
 <div class='top_list'>
   <h3 class='top_subtitle'>Class</h3>
   <% klasses.each do |klass| %>
   <span><a class=<%= class_link(klass) %> href="#<%= klass %>"><%= klass %></a> | </span>
   <% end %>
   <span class="counter"><%= klasses.length %></span>
 </div>
 <div class='top_list'>
   <h3 class='top_subtitle'>Module</h3>
   <% modules.each do |mod| %>
   <span><a class=<%= class_link(mod) %> href="#<%= mod %>"><%= mod %></a> | </span>
   <% end %>
   <span class="counter"><%= modules.length %></span>
 </div>
 <div class='top_list'>
   <h3 class='top_subtitle'>Exception Class</h3>	    
   <% error_klasses.each do |error| %>
   <span><a class=<%= class_link(error) %> href="#<%= error %>"><%= error %></a> | </span>
   <% end %>
   <span class="counter"><%= error_klasses.length %></span>
 </div>
 <div class='top_list'>
   <h3 class='top_subtitle'>Standard Library</h3>	    
   <% libraries.each do |lib| %>
   <span><a class="top_class_link" href="<%= RUBY_REF %>library/<%= lib %>"><%= lib %></a> | </span>
   <% end %>
   <span class="counter"><%= libraries.length %></span>
 </div>
 <div class='top_list'>
   <h3 class='top_subtitle'>Links</h3>	    
   <% USEFUL_LINKS.each do |name, site| %>
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
     <a class="class_link" id='class_name' href="<%= RUBY_REF %>class/<%= enum_class_check(klass) %>"><%= klass %></a><span id='class_suffix'> <%= klass.class %></span>
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
     <% method_list(klass).each do |meth_type, meths| %>
       <h3 class='meth_type'><%= meth_type %></h3>
       <% meths.sort.each_with_index do |meth, i| %>
         <span>
           <a class=<%= method_link(klass,meth_type,meth) %> href=<%= ruby_man_method_link(klass,meth_type,meth) %>><%= meth %></a>
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
   			<span><a class='meth_link' href="<%= RUBY_REF %>method/Kernel/c/<%= const %>"><%= const %></a> | </span>
   		<% end %>
 		<% end %>
   </div>
 <% end %>

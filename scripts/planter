#!/usr/bin/ruby
# ruby script to create a directory structure from indented data.
# Three ways to use it:
# - Pipe indented (tabs or 2 spaces) text to the script
#   - e.g. `cat "mytemplate" | planter.rb
# - Create template.tpl files in ~/.planter and call them by their base name
#   - e.g. Create a text file in ~/.planter/site.tpl
#   - `planter.rb site`
# - Call planter.rb without input and it will open your $EDITOR to create the tree on the fly
# You can put %%X%% variables into templates, where X is a number that corresponds to the index
# of the argument passed when planter is called.
# e.g. `planter.rb client "Mr. Butterfinger"` would replace %%1%% in client.tpl with "Mr. Butterfinger"

require 'yaml'
require 'tmpdir'
require 'fileutils'

def get_hierarchy(input,parent=".",dirs_to_create=[])
  input.each do |dirs|
    if dirs.kind_of? Hash
      dirs.each do |k,v|
          dirs_to_create.push(File.expand_path("#{parent}/#{k.strip}"))
          dirs_to_create = get_hierarchy(v,"#{parent}/#{k.strip}",dirs_to_create)
      end
    elsif dirs.kind_of? Array
      dirs_to_create = get_hierarchy(dirs,parent,dirs_to_create)
    elsif dirs.kind_of? String
      dirs_to_create.push(File.expand_path("#{parent}/#{dirs.strip}"))
    end
  end
  return dirs_to_create
end

def text_to_yaml(input, replacements = [])
  lines = input.split("\n")
  output = []
  prev_indent = 0
  lines.each_with_index do |line, i|
    if line =~ /%%(\d+)%%/
      if $1.to_i <= replacements.length
        line.gsub!(/%%#{$1}%%/,replacements[$1.to_i - 1])
      else
        $stderr.puts('Mismatch in number of template variables found and replacements provided')
        lines[i] = ''
        next
      end
    end
    indent = line.gsub(/  /,"\t").match(/(\t*).*$/)[1]
    if indent.length > prev_indent
      lines[i-1] = lines[i-1].chomp + ":"
    end
    prev_indent = indent.length
    lines[i] = indent.gsub(/\t/,'  ') + "- " + lines[i].strip # unless indent.length == 0
  end
  lines.delete_if {|line|
    line == ''
  }
  return "---\n" + lines.join("\n")
end

if STDIN.stat.size > 0
  data = STDIN.read
elsif ARGV.length > 0
  template = File.expand_path("~/.planter/#{ARGV[0].gsub(/\.tpl$/,'')}.tpl")
  ARGV.shift
  if File.exists? template
    File.open(template, 'r') do |infile|
      data = infile.read
    end
  else
    puts "Specified template not found in ~/.planter/*.tpl"
  end
else
  tmpfile = File.expand_path(Dir.tmpdir + "/planter.tmp")
  File.new(tmpfile, 'a+')

  # at_exit {FileUtils.rm(tmpfile) if File.exists?(tmpfile)}

  %x{$EDITOR "#{tmpfile}"}
  data = ""
  File.open(tmpfile, 'r') do |infile|
    data = infile.read
  end
end

data.strip!

yaml = YAML.load(text_to_yaml(data,ARGV))
dirs_to_create = get_hierarchy(yaml)

dirs_to_create.each do |dir|
  $stderr.puts "Creating #{dir}"
  Dir.mkdir(dir) unless File.exists? dir
end

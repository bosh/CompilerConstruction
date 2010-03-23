require "simpLex.rb"

class Tree
  attr_accessor :root
  def initialize(node)
    @root = node #would be great to make this non-destructive via full copying of data, but that doesn't matter for a one-shot
    @root.orphan! #technically unnecessary
  end
  def full_print
    @root.tree_print
  end
  def full_stringify
    @root.tree_stringify
  end
end

class Node
  attr_accessor :contents, :parent, :text
  def initialize(parent, text)
    @contents = []
    @parent = parent
    @text = text
  end
  def tree_print(level = 0)
    level.times{print "\t"}
    puts @text
    @contents.each{|c| c.tree_print(level+1)}
  end
  def tree_stringify(level = 0)
    str = ""
    level.times{str << "\t"}
    str << @text
    @contents.each{|c| str << tree_stringify(level+1)}
    str
  def orphan!
    @parent = nil
  end
end

class Parser
  attr_accessor :filename, :tokens, :current_token, :token_head, :options. :tree
  def initialize(filename, opts = {})
    @tree = nil
    @filename = filename
    @current_token = @token_head = 0
    @tokens = []
    @options = opts
    if @options[:from_tokens]
      import_token_stream(@filename)
    else
      lexer_token_stream(@filename)
    end
    if @options[:full] : parse; end
    if @options[:stdout] || @options[:full] : emit_tree; end
  end
  def import_token_stream(filename)
    stream = []
    File.open(filename) do |f|
      lines = f.readlines
      i = 0
      until i > lines.size-1 do #last line is blank
        line = lines[i]
        type = ( /\A(\w+)/ =~ line) ? $1 : line
        value = line[type.length..-1] #skip the delimiting space
        if value[1, 1] == '"' #second in string is "
          while value[value.length-2, 1] != '"' #value isn't terminated by a "
            i += 1
            value += lines[i] #append the next line
          end
          value = value[1...-1] #get rid of starting quote and last char (\n, the " will be handled below)
        end
        value = value[1...-1] #get rid of first and last char (" " and then \n normally, " if went through the if/while)
        stream << Token.new("",type, value) #oh look, token needs a factoring
        i += 1
      end
    end
  end
  def lexer_token_stream(filename)
    lex = Lexer.new(filename, {:internal => true, :full => true})
  end
  def emit_tree
    if @options[:stdout] : @tree.full_print; end
    if @options[:file] : text = @tree.full_stringify; end
  end
  def parse
    #the magic
    #match(start_symbol)
    @tree = root
  end
end

$start_symbol = "Program"
if $0 == __FILE__
  if ARGV.size == 0 || ARGV[0] == "-h" || ARGV[0] == "help"
    puts "Welcome to simParse,
\ta simple parser for a pascal-variant grammar
\nsimParse works together with simpLex to analyze and parse your programs.
\n\tTo use:\n\t\truby simParse _filename_ [options]
\n\tOptions:
\t\t[-s|-f]\t- Stdout OR fileout. File out will be _filename_parsed.txt
\t\t-o\t\t- If mode -f, will overwrite any file with the same target name
\t\t[-a|-n]\t- Full run OR no run. No run is default\n"
  else
    opts = {}
    filename = ARGV[0]
    ARGV.each do |arg|
      case arg
        when "-n" : opts[:full]      = false
        when "-a" : opts[:full]       = true
        when "-o" : opts[:overwrite]  = true
        when "-s" : opts[:stdout]     = opts[:full] = true
        when "-f" : opts[:file]     = opts[:full] = true
      else
        puts "Unrecognized option: '#{arg}'. Attempting run anyway."
      end
    end
    parser = Parser.new(ARGV[0], opts)
  end
end

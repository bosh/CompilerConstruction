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
  end
  def orphan!
    @parent = nil
  end
end

class Rule
  attr_accessor :name, :productions
  def initialize(name, text)
    @name = name.strip
    @text = text.strip
    create_productions
  end
  def create_productions
    @productions = []
    top_level_productions = TODO
    top_level_productions.each do |production|
      @productions << Production.new(production)
    end
  end
end

class Production
  attr_accessor :text, :subproductions, :type
  def initialize(text)
    @text = text.strip
    set_type
    create_subproductions
  end
  def set_type
    @type = TODO
  end
  def create_subproductions
    @subproductions = []
    TODO
  end
end

class GrammarGenerator
  attr_accessor :filename, :grammartext, :grammar, :name
  def initialize(filename)
    @filename = filename
    File.load(@filename).read.match(/T(O)D(O)/m)
    @name = $1
    @grammartext = $2
    create_grammar
  end
  def create_grammar
    @grammar = {}
    set_start_symbol
    create_rules
  end
  def set_start_symbol
    @grammar[:start_symbol] = get_start_symbol
  end
  def get_start_symbol
    @grammartext.match( /start_symbol :(\w+)/ )
    $1.to_sym
  end
  def create_rules
    rules_in_text = @grammartext.scan(/rule\s+(\w+)\s+(.*?)\s+endrule/m)
    rules_in_text.each{|ruletext| add_rule(ruletext)}
  end
  def add_rule(ruletext)
    rule = Rule.new(ruletext[0], ruletext[1]) #0 is the name, 1 is text
    register_rule(rule)
  end
  def register_rule(rule)
    @grammar[rule.name] = rule
  end
end

class Parser
  attr_accessor :filename, :options, :grammar_rules, :tree, :tokens
  def initialize(filename, opts = {})
    @options = opts
    @filename = filename
    load_grammar_rules(@options[:grammar_file])
    if @options[:from_tokens]
      import_token_stream(@filename)
    else
      lexer_token_stream(@filename)
    end
    if @options[:full] : parse; end
    if @options[:stdout] || @options[:full] : emit_tree; end
  end
  def load_grammar_rules(filename)
    @grammar_rules = GrammarLoader.new(filename).grammar
  end
  def import_token_stream(filename)
    @tokens = []
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
        @tokens << Token.new("",type, value) #oh look, token needs a factoring
        i += 1
      end
    end
  end
  def lexer_token_stream(filename)
    @tokens = Lexer.new(filename, {:internal => true, :full => true}).token_list
  end
  def emit_tree
    if @options[:stdout] : @tree.full_print; end
    if @options[:file]
      text = @tree.full_stringify
      if @options[:overwrite] || !File.exists?(@filename)
        File.new(@filename, "w")
        File.open(@filename, 'a') {|f| f.write(text)}
      end
    end
  end
  def start_symbol
    @grammar_rules[:start_symbol]
  end
  def match(symbol)
    TODO
  end
  def parse
    result = match(start_symbol)
    #if result.error?
    #  puts result.message
    #  exit(0)
    #else
      @tree = Tree.new(result)
    #end
  end
end

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
        when "-g" : opts[:grammar_file] = filename#.drop_extension.add__grammar.grm #BROKEN FOR NOW
      else
        puts "Unrecognized option: '#{arg}'. Attempting run anyway."
      end
    end
    opts[:grammar_file] ||= "simParse_grammar.grm"
    parser = Parser.new(ARGV[0], opts)
  end
end

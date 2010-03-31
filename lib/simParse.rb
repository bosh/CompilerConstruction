require 'simpLex'

class Tree
  attr_accessor :root
  def initialize(node)
    @root = node  #would be great to make this non-destructive via full copying of data, but that doesn't matter for a one-shot
    @root.orphan! #technically unnecessary
  end
  
  def full_print; @root.tree_print          end
  def full_stringify; @root.tree_stringify  end
  
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
  
  def orphan!; @parent = nil end
  
end

class Rule
  attr_accessor :name, :text, :productions
  def initialize(name, text)
    @name = name.strip
    @text = text.strip
    create_productions
  end
  def create_productions
    @productions = []
    if ( /\A\((.*)\)\z/ =~ @text) #that means it's wrapped in ()s, ie has top level productions
      @text = @text[1...-1].strip #Kill the parens
      @text.gsub!("/", "//") #Means there can be no /'s in a rule with multiple productions
      top_level_productions = @text.scan( /(\A|\/)(.*?)(\z|\/)/m )
      top_level_productions.each do |production|
        @productions << Production.new(production[1])
      end
    else #there's only one top level rule
      @productions << Production.new(@text)
    end
  end
  def match?
    @productions.each do |p|
      matcher = if p.required? #probably factorable or movable into another class...
        p.match?() #no extra params
      elsif p.optional?
        p.match?() #TODO note optionality
      elsif p.repeating?
        p.match?() #TODO note repeated checking
      end
      handle_matcher(matcher)
    end
  end
  def handle_matcher(matcher)
    TODO
  end
end

class Production
  attr_accessor :text, :subproductions, :type
  def initialize(text, type = "")
    @text = text.strip
    @type = type
    set_type unless type
    create_subproductions
  end
  def set_type
    if @text =~       /\A\(.*\)\z/ : @type = :group
      elsif @text =~  /\A\{.*\}\z/ : @type = :repeating
      elsif @text =~  /\A\[.*\]\z/ : @type = :optional
    else
      @type = :basic
    end
    if wrapped?; unwrap! end
  end
  
  def wrapped?; [:optional, :repeating, :group].include? @type end
  def unwrap!; @text = @text[1...-1].strip end
  
  def create_subproductions
    @subproductions = []
    until @text.empty? : @subproductions << grab_next_metasymbol end
  end
  def grab_next_metasymbol #this is an easy factor (the $1s)
    matcher_type = nil
    if @text =~       /\A"(.*?)"/     : matcher_type = :literal
      elsif @text =~  /\A([a-z]\w*)/  : matcher_type = :type
      elsif @text =~  /\A([A-Z]\w*)/  : matcher_type = :metasymbol
      elsif @text =~  /\A(\[.*?\])/   : matcher_type = :optional
      elsif @text =~  /\A(\{.*?\})/   : matcher_type = :repeating
      elsif @text =~  /\A(\(.*?\))/   : matcher_type = :group
    else
      #should not be here =)
    end
    @text = @text[($1.length+(matcher_type == :literal ? 2 : 0 ))..-1].strip
    create_matcher($1, matcher_type)
  end
  def create_matcher(text, type)
    if [:optional, :repeating, :group].include? type
      Rule.new("anonymous", text) #now with infinite recursion awesomeness
    else
      Matcher.new(text, type)
    end
  end
end

class Matcher
  attr_accessor :text, :type
  def initialize(text, type)
    @text = text
    @type = type
  end
  def match?(token)
    if @type == "literal"         : @text == token.value
      elsif @type == "type"       : @text == token.type
      elsif @type == "metasymbol" : $parser.grammar_rules[text.to_sym].match?(token)
    else
      #should never be here =)
    end
  end
end

class GrammarGenerator
  attr_accessor :filename, :grammartext, :grammar, :name
  def initialize(filename)
    @filename = filename
    File.open(@filename).read.match(/grammar\s+(\w+)\s+(.*?)endgrammar/m)
    @name = $1
    @grammartext = $2
    create_grammar
  end
  def create_grammar
    @grammar = {}
    set_start_symbol
    create_rules
  end
  def get_start_symbol
    @grammartext.match( /start_symbol :(\w+)/ )
    $1.to_sym
  end
  
  def set_start_symbol; @grammar[:start_symbol] = get_start_symbol end
  def create_rules; @grammartext.scan(/rule\s+(\w+)\s+(.*?)\s+endrule/m).each{|ruletext| add_rule(ruletext)} end
  def add_rule(ruletext); register_rule(Rule.new(ruletext[0], ruletext[1])) end
  def register_rule(rule); @grammar[rule.name] = rule end
  
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
    @grammar_rules = GrammarGenerator.new(filename).grammar
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
    filename = ARGV.delete_at(0)
    ARGV.each do |arg|
      case arg
        when "-n" : opts[:full]         = false
        when "-a" : opts[:full]         = true
        when "-o" : opts[:overwrite]    = true
        when "-s" : opts[:stdout]       = opts[:full] = true
        when "-f" : opts[:file]         = opts[:full] = true
        when "-g" : opts[:grammar_file] = filename#.drop_extension.add__grammar.grm #BROKEN FOR NOW
      else
        puts "Unrecognized option: '#{arg}'. Attempting run anyway."
      end
    end
    opts[:grammar_file] ||= "simParse_grammar.grm"
    parser = Parser.new(filename, opts)
  end
end

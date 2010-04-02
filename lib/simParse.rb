require 'simpLex'
$current_index = 0

class TrueClass
  def backtrack; true end
  def nonfatal?; true end
  def tree_print(what); "TruePrint: #{what}" end
  def children; [] end
end

class Array
  def tree_print(level); self.each{|m| m.tree_print(level)} end
  def backtrack; self.each{|i| i.backtrack} end
  
  def tree_stringify(level)
    str = ""
    self.each{|m| str << m.tree_stringify(level)}
    str
  end
end

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
  attr_accessor :children, :parent, :content
  def initialize(content, parent = nil)
    @children = []
    @parent = parent
    @content = content
  end
  def tree_print(level = 0)
    level.times{print "|\t"}
    puts @content.to_s.strip #The to_s currently has extra tabbage
    @children.each{|c| c.tree_print(level+1)}
  end
  def tree_stringify(level = 0)
    str = ""
    level.times{str << "|\t"}
    str << @content.to_s
    str << "\n"
    @children.each{|c| str << c.tree_stringify(level+1)}
    str
  end
  
  def backtrack; @children.each{|c| c.backtrack } end
  def nonfatal?; !([:fatal, :literal_mismatch, :type_mismatch, :subrule_mismatch].include?(@content) )end
  def acceptable_nonmatch?; [:optional_fail , :repeater_fail].include?(@content) end
  def orphan!; @parent = nil end
  def to_s; "|#{@content}: #{@children}|" end
end

class Rule
  attr_accessor :name, :text, :productions
  def initialize(name, text)
    @name = name.strip
    @text = text.strip
    create_productions
  end
  def to_s
    txt = "\nRule: #{@name}:\nText: ~#{@text}~\n"
    @productions.each{|p| txt << p.to_s; txt << "\n"}
    txt
  end
  def create_productions
    @productions = []
    if ( /\A\((.*)\)\z/m =~ @text) #that means it's wrapped in ()s, ie has top level productions
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
  def match?(tokenstream)
    #puts "#{$current_index} #{@name}"
    match_node = nil
    @productions.each do |p|
      match_node = p.match?(tokenstream) #no extra params
      if match_node.class == Node && match_node.nonfatal?
        break
      else
        if match_node.acceptable_nonmatch?
          match_node = Node.new(:optional_fail)
        else
          match_node = Node.new(:fatal)
        end
      end
    end
    match_node
  end
end

class Production
  attr_accessor :text, :subproductions, :type
  def initialize(text)
    @text = text.strip
    @type = type
    set_type!
    create_subproductions
  end
  def to_s
    txt = "--Production: #{@type}"
    @subproductions.each{|s| txt <<"\n\tSP:"; txt << s.to_s}
    txt
  end
  def set_type!
    if @text =~  /\A\{.*\}\z/ : @type = :repeating
      elsif @text =~  /\A\[.*\]\z/ : @type = :optional
    else
      @type = :basic
    end
    if wrapped?; unwrap! end
  end
  
  def wrapped?; [:optional, :repeating, :group].include? @type end
  def unwrap!; @text = @text[1...-1].strip end
  def required?; @type != :repeating && @type != :optional end
  def optional?; @type == :optional end
  def repeating?; @type == :repeating end
  
  def create_subproductions
    @subproductions = []
    until @text.empty? : @subproductions << matchmake_next_metasymbol end
  end
  def matchmake_next_metasymbol
    matcher_type = nil #easy switch statement factor
    if @text =~       /\A"(.*?)"/     : matcher_type = :literal
      elsif @text =~  /\A([a-z]\w*)/  : matcher_type = :type
      elsif @text =~  /\A([A-Z]\w*)/  : matcher_type = :metasymbol
      elsif @text =~  /\A(\[.*?\])/   : matcher_type = :optional
      elsif @text =~  /\A(\{.*?\})/   : matcher_type = :repeating
      elsif @text =~  /\A(\(.*?\))/   : matcher_type = :group
    else
      puts "FATAL ERROR: #{matcher_type}||#{@text}"
    end
    @text = @text[($1.length+(matcher_type == :literal ? 2 : 0 ))..-1].strip
    create_matcher($1, matcher_type)
  end
  def create_matcher(text, type)
    if [:optional, :repeating, :group].include? type
      Rule.new("anonymous", text)
    else
      Matcher.new(text, type)
    end
  end
  def match?(tokenstream)
    #puts " #{$current_index}\t#{@text}"
    matches = []
    fatal = false
    @subproductions.each do |s|
      match = s.match?(tokenstream) #expecting match to be a node
      fatal = true if match.nil? || !match.nonfatal?
      break if fatal
      if match.acceptable_nonmatch? : match.backtrack; next end
      matches << match
    end
    if fatal && required?
      matches.each{|m| m.backtrack }
      return Node.new(:fatal)
    elsif !fatal && required?
      n = Node.new(@subproductions)
      n.children = matches
      return n
    elsif optional?
      if !fatal
        n = Node.new(@subproductions)
        n.children = matches
        return n
      else
        n = Node.new(:optional_fail)
        n.children = matches
        return n
      end
    elsif repeating?
      if !fatal
        tail = match?(tokenstream) #This is why there is backtracking and a global pointer
        if tail.class == Node : matches << tail.children end
        n = Node.new(@subproductions)
        n.children = matches
        return n
      else
        n = Node.new(:repeater_fail)
        n.children = matches
        return n
      end
    else #this means you're invalid and nobody loves you
      return (soft_fail = false) #This is an exterior (TODO)
    end
  end
end

class Matcher
  attr_accessor :text, :type
  def initialize(text, type)
    @text = text
    @type = type.to_s
  end
  def to_s
    "\t--Matcher: #{@text}\t#{@type}"
  end
  def match?(tokenstream)
    #puts "  #{$current_index}\t\t#{@text}|#{@type}"
    token = tokenstream[$current_index]
    if @type == "literal"
      if @text == token.value
        $current_index += 1
        Node.new(token)
      else
        matcher_fail(:literal_mismatch)
      end
    elsif @type == "type"
      if token && @text.downcase == token.type.downcase
        $current_index += 1
        Node.new(token)
      else
        matcher_fail(:type_mismatch)
      end
    elsif @type == "metasymbol"
      result = $parser.grammar_rules[text].match?(tokenstream)
      if result #TODO check that is it a sucess, not just empty
        result
      else
        matcher_fail(:subrule_mismatch) #TODO This is all factorable
      end
    else #all types should be accounted for
      puts "FATAL ERROR: Class: Matcher, Method: match?(), Name: #{@type}: #{@text}"
    end
  end
  
  def backtrack; $current_index -= 1 end
  def matcher_fail(how); Node.new(how) end #as in what's the symbol for how it failed
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
  end
  def after_create
    print_grammar if @options[:debug]
    parse if @options[:full]
    emit_tree if @options[:stdout] || @options[:full]
  end
  def print_grammar
    @grammar_rules.each do |r|
      puts r.to_s
    end
    puts "Start Symbol: #{@grammar_rules[:start_symbol]}"
  end
  def load_grammar_rules(filename)
    @grammar_rules = GrammarGenerator.new(filename).grammar
  end
  def import_token_stream(filename) #This is fucking terrible. I'm sorry!
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
      @filename =~ /\A(.*)\.\w+\z/
      outfile = $1 << "_parsed.txt"
      if @options[:overwrite] || !File.exists?(outfile)
        puts "Writing to file!"
        File.new(outfile, "w")
        File.open(outfile, 'a') {|f| f.write(text)}
      end
    end
  end
  def start_symbol
    @grammar_rules[:start_symbol].to_s
  end
  def match?(symbol)
    $current_index = 0
    @grammar_rules[start_symbol].match?(@tokens)
  end
  def parse
    result = match?(start_symbol)
    if result && result.nonfatal?
      @tree = Tree.new(result)
    else
      puts "Parser failed at parsing. Soz."
      exit(0)
    end
  end
end

if $0 == __FILE__
  if ARGV.size == 0 || ARGV.include?("-h") || ARGV.include?("help")
    puts "Welcome to simParse,
\ta simple parser for a pascal-variant grammar
\nsimParse works together with simpLex to analyze and parse your programs.
\nTo use:\n\truby simParse _filename_ [options]
\nOptions:
\t[-s|-f]\t- Stdout OR fileout. File out will be _filename_parsed.txt
\t-o\t- If mode -f, will overwrite any file with the same target name
\t[-a|-n]\t- Full run OR no run. No run is default\n
\t\t(BONUS! -d - Print grammar constructs to the command line...)"
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
        when "-d" : opts[:debug] = true
      else
        puts "Unrecognized option: '#{arg}'. Attempting run anyway."
      end
    end
    opts[:grammar_file] ||= "simParse_grammar.grm"
    $parser = Parser.new(filename, opts)
    $parser.after_create
  end
end

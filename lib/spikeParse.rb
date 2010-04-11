require 'simpLex'
require 'string_helper'
$current_index = 0
$debug = true #TODO delete for production
def debug?; $debug end 

class Tree
  attr_accessor :root
  def initialize(node = nil); @root = node          end
  def print;                  puts stringify        end
  def stringify;              @root.tree_stringify  end
end

class Node
  attr_accessor :children, :parent, :content
  def initialize(content, parent = nil, children = [])
    @content = content
    @parent = parent
    @children = children
  end
  def tree_stringify(level = 0)
    str = ""
    level.times{str << "|\t"}
    str << to_s
    @children.each{|c| str << "\n#{c.tree_stringify}"}
    str
  end
  def backtrack
    @content.backtrack #TODO leave only if content itself is an object that implements backtrack
    @children.each{|c| c.backtrack}
  end

  def to_s; "Node: #{@content.to_s}" end
  def parse_error?; @content =~ /ERROR/ end #TODO this is mostly fake :)
end

class Rule
  attr_accessor :name, :text, :productions, :type
  def initialize(name, text)
    @name = name.strip
    @text = text.strip
    @productions = []
    @type = :basic #The only nonbasics are opt/repeating
    create_productions
  end
  def to_s
    "Rule: #{@name}, #{@productions.size} top level productions"
  end
  def to_ruletext
    str = to_s
    @productions.each{|p| str << "\n\t#{p.to_extended}"}
    str
  end
  def create_productions
    identify_productions.each{|p| add_production(p)}
  end
  def identify_productions
    prods = []
    if @text.wrapped?("(", ")") #Major limitation, there may not be different option sets in a rule at the same level/depth
      choice_productions.each{|p| prods << p}
    elsif @text.wrapped?("{", "}") #Major limitation again, no starting and ending with different option blocks
      @type = :repeating
      prods << @text[1...-1].strip
    elsif @text.wrapped?("[", "]") #Major limitation again, no starting and ending with different option blocks
      @type = :optional
      prods << @text[1...-1].strip
    end
    prods
  end
  def choice_productions
    subs = @text[1...-1].strip
    subs.gsub!("/", "//") #Major limitation, in that rules with /'s cannot have literal /'s
    subs.scan(/(\A|\/)(.*?)(\z|\/)/m).map{|i| i[1]}
  end
  def add_production(text)
    @productions << Production.new(text)
  end
  def match?
    #TODO
  end
end

class Production
  attr_accessor :text, :subproductions
  def initialize(text)
    @text = text.strip
    @subproductions = []
    create_subproductions
  end
  def create_subproductions
    until @text.empty? : @subproductions << subproduce_next_metasymbol end
  end
  def subproduce_next_metasymbol
    m_type = nil
    case @text
      when /\A"(.*?)"/ : m_type= :literal
      when /\A([a-z]\w*)/ : m_type = :type
      when /\A([A-Z]\w*)/ : m_type = :metasymbol
      when /\A(\[.*?\])/ : m_type = :optional
      when /\A(\{.*?\})/ : m_type = :repeating
      when /\A(\(.*?\))/ : m_type = :choice #Perhaps should be multiline (should all be?)
      else
        puts "FATAL ERROR IN METASYMBOL ANALYSIS: #{@text}"
    end
    sub_text = $1
    @text = @text[(sub_text.length + ((m_type == :literal)? 2 : 0))..-1].strip
    create_matcher(sub_text, m_type)
  end
  def create_matcher(text, type)
    if [:optional, :repeating, :choice].include? type
      Rule.new("anonymous", text)
    else
      Matcher.new(text, type)
    end
  end
  def to_s
    "Production: #{@text}, #{@type}, #{@subproductions.size} subproductions"
  end
  def to_extended
    str = to_s
    @subproductions.each{|s| str << "\n\t\t#{s.to_extended}"}
    str
  end
end

class Matcher
  attr_accessor :text, :type
  def initialize(text, type)
    @text = text
    @type = type
  end
  def match?
    #TODO
  end

  def backtrack; $current_index -= 1 end #TODO This may need looking into/solution VS node.backtrack
  def to_s; "Matcher: #{@text},\t#{@type}" end
  def to_extended; to_s end
end
  
class GrammarGenerator
  attr_accessor :filename, :grammar_text, :grammar, :name, :start_symbol
  def initialize(filename)
    @filename = filename
    read_grammar_file
    @grammar = {}
    create_grammar
  end
  def read_grammar_file
    File.open(@filename) do |f|
      f.read.match(/grammar\s+(\w+)\s+(.*?)endgrammar/m)
      @name = $1
      @grammar_text = $2
    end
  end
  def create_grammar
    identify_start_symbol
    create_rules
  end
  def identify_start_symbol
    @grammar_text.match( /start_symbol :(\w+)/ )
    @start_symbol = $1.to_sym
  end
  def create_rules
    rules = @grammar_text.scan( /(\A|\s+)rule\s+(\w+)\s+(.*?)\s+endrule/m )
    rules.each do |r|
      name = r[1]
      text = r[2]
      register_rule(Rule.new(name, text))
    end
  end
  def register_rule(rule)
    if !registered?(rule)
      @grammar[rule.name] = rule
    else
      puts "Rule name conflict: #{rule.name}"
    end
  end
  def registered?(rule)
    @grammar[rule.name]
  end
end

class Parser
  attr_accessor :filename, :options, :grammar, :tree, :tokens
  def initialize(filename, opts = {})
    @options = opts
    @filename = filename
    load_grammar_rules
    load_token_steam
  end
  def after_create
    print_grammar if debug?
    parse if parse_after_create?
    emit_tree if emit_after_create? #TODO can't have a tree without parsing, so this could be inside the prev if
  end
  def load_grammar_rules
    @grammar = GrammarGenerator.new(@options[:grammar_file])
  end
  def load_token_steam
    (premade_token_stream?)? load_textfile_tokens : load_simplex_tokens
  end
  def load_textfile_tokens
    @tokens = []
    lines = []
    File.open(@filename){|f| lines = f.readlines}
    while lines && lines.size > 0 #lines to make sure it isn't nil
      lines.shift =~ /\A(\w+)\s+(.*)\z/
      type = $1
      value = $2.strip
      if value[0,1] == '"'
        until value[-1,1] == '"' #or could do until value.quoted?
          value << "\n#{lines.shift.strip}"
        end
        value.dequote!
      end
      @tokens << Token.new("", type, value) #TODO still needs a cleanup
    end
  end
  def load_simplex_tokens
    lex = Lexer.new(@filename, {:internal => true, :full => true})
    @tokens = lex.token_list
  end
  def parse
    result = match?(@grammar.start_symbol)
    if result.parse_error?
      puts "Parse error: #{result}"
      exit(0) #TODO find a proper, in-module way to do this
    else
      @tree = Tree.new(result)
    end
  end
  def emit_tree
    @tree.print if cmd_line_output?
    if file_output?
      @filename =~ /\A(.*)\.\w+\z/
      outfile = "#{$1}_parsed.txt"
      if overwrite_output? || !File.exists?(outfile)
        puts "Parse successful! Writing to file #{outfile}."
        File.new(outfile, 'w') #TODO can i make this one line?
        File.open(outfile, 'a'){|f| f.write(@tree.stringify)}
      end
    end
  end
  def print_grammar
    puts "Grammar: #{@grammar.name}"
    grammar_rules.each do |g|
      puts g.to_extended
    end
    puts "Start Symbol: #{@grammar.start_symbol}"
  end#may need more specificity depending on what a hash.to_s is
  def match?
    #TODO
  end
  
  def parse_after_create?;    @options[:full]         end
  def file_output?;           @options[:file]         end
  def grammar_rules;          @grammar.grammar        end
  def cmd_line_output?;       @options[:stdout]       end
  def overwrite_output?;      options[:overwrite]     end
  def premade_token_stream?;  @options[:from_tokens]  end
  def emit_after_create?;     @options[:full] || @options[:stdout]  end
end

if $0 == __FILE__
  if ARGV.size == 0 || ARGV.include?("-h") || ARGV.include?("help")
    puts "EXPLODING BETA MODE OF SUPER AWESOME POWER"
  else
    opts = {}
    filename = ARGV.delete_at(0)
    ARGV.each do |arg|
      case arg
        when "-a" : opts[:full]         = true
        when "-d" : opts[:debug]        = true
        when "-f" : opts[:file]         = opts[:full] = true
        #when "-g" : opts[:grammar_file] = filename#.drop_extension.add__grammar.grm #BROKEN
        when "-n" : opts[:full]         = false
        when "-o" : opts[:overwrite]    = true
        when "-s" : opts[:stdout]       = opts[:full] = true
      else
        puts "Unrecognized option: '#{arg}'. Attempting run anyway."
      end
    end
    opts[:grammar_file] ||= "simParse_grammar.grm"
    $parser = Parser.new(filename, opts)
    $parser.after_create
  end
end

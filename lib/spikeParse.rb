require 'simpLex'
$current_index = 0
$debug = true #TODO delete for production
def debug?; $debug end
class String #TODO make a helper and require it
  def quoted?(style = :both)
    if self[0,1] == self[-1,1]
      if style == :single
        self[0,1] == "'"
      elsif style == :double
        self[0,1] == '"'
      else #both or an unrecognized, which defaults to both
        self[0,1] == '"' || self[0,1] == "'"
      end
    else
      false
    end
  end
  def dequote!
    replace(dequote)
  end
  def dequote #and strip. TODO: it may actually be poor form to _include_ the quoted check
    if self.quoted?
      return self[1...-1].strip
    else
      return self #TODO or should this be a false/nil/error?
    end
  end
end 

class Tree
  attr_accessor :root
  def initialize(node = nil)
    @root = node
  end
  def print
    puts stringify
  end
  def stringify
    @root.tree_stringify
  end
end

class Node
  attr_accessor :children, :parent, :content
  def initialize(content, parent = nil, children = [])
    @content = content
    @parent = parent
    @children = children
  end

  def parse_error?; @content =~ /ERROR/ end #TODO this is mostly fake :)
  def to_s #to_s is the single node version, it doesn't recurse on children
    "Node: #{@content.to_s}"
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
end

class Rule
  attr_accessor :name, :text, :productions
  def initialize(name, text)
  end

end

class Production
  attr_accessor :text, :subproductions, :type
  def initialize(text)
  end

end

class Matcher
  attr_accessor :text, :type
  def initialize(text, type)
  end
end
  
class GrammarGenerator
  attr_accessor :filename, :grammartext, :grammar, :name
  def initialize(filename)
  end
  
end

class Parser
  attr_accessor :filename, :options, :grammar_rules, :tree, :tokens
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
    g = GrammarGenerator.new(@options[:grammar_file])
    @grammar_rules = g.grammar #a hash
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
    result = match?(start_symbol)
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
  def match?
    #TODO
  end
  
  def parse_after_create?; @options[:full] end
  def cmd_line_output?; @options[:stdout] end
  def file_output?; @options[:file] end
  def emit_after_create?; @options[:full] || @options[:stdout] end
  def premade_token_stream?; @options[:from_tokens] end
  def print_grammar; puts @grammar_rules end#may need more specificity depending on what a hash.to_s is
  def overwrite_output?; options[:overwrite] end
  def start_symbol; @grammar_rules[:start_symbol].to_s end
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

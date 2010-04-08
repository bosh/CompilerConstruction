require 'simpLex'
$current_index = 0

class Tree
  attr_accessor :root
  def initialize(node)
  end
  
end

class Node
  attr_accessor :children, :parent, :content
  def initialize(content, parent = nil)
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
    emit_tree if emit_after_create?
  end
  
  def debug?; $debug end
  def parse_after_create?; @options[:full] end
  def cmd_line_output?; @options[:stdout] end
  def file_output?; @options[:file] end
  def emit_after_create?; @options[:full] || @options[:stdout] end
  def premade_token_stream? @options[:from_tokens] end
  def start_symbol; @grammar_rules[:start_symbol].to_s end
  def print_grammar; puts @grammar_rules end#may need more specificity depending on what a hash.to_s is
  def overwrite_output?; options[:overwrite] end
  
  def load_grammar_rules
    GrammarGenerator.new(@options[:grammar_file]) do |g| #TODO does this work
      @grammar_rules = g.grammar #a hash
    end
  end
  def load_token_steam
    (premade_token_stream?)? load_textfile_tokens : load_simplex_tokens
  end
  def load_simplex_tokens
    Lexer.new(@filename, {:internal => true, :full => true}) do |lex|
      @tokens = lex.token_list #TODO does this work
    end
  end
  def load_textfile_tokens
    #grossness
  end
  def parse
    result = match?(start_symbol)
    #TODO moar
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
end

if $0 == __FILE__
  if ARGV.size == 0 || ARGV.include?("-h") || ARGV.include?("help")
    puts "EXPLODING BETA MODE OF SUPER AWESOME POWER"
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

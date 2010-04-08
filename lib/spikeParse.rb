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
  def load_grammar_rules
    GrammarGenerator.new(@options[:grammar_file]) do |g| #does this work
      @grammar_rules = g.grammar #a hash
    end
  end
  def load_token_steam
    (premade_token_stream?)? load_textfile_tokens : load_simplex_tokens
  end
  def premade_token_stream?
    @options[:from_tokens]
  end
  def load_simplex_tokens
    Lexer.new(@filename, {:internal => true, :full => true}) do |lex|
      @tokens = lex.token_list
    end
  end
  def load_textfile_tokens
    #grossness
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
  end
end

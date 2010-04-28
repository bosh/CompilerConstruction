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
    @start_symbol = $1
  end
  def create_rules
    rules = @grammar_text.scan( /(\A|\s+)rule\s+(\w+)\s+(.*?)\s+endrule/m )
    rules.each do |r|
      name = r[1]
      text = r[2]
      register_rule(name, text)
    end
  end
  def register_rule(name, text)
    rule = Rule.new(name, text)
    if !registered?(rule)
      @grammar[rule.name] = rule
    else
      puts "Rule name conflict: #{rule.name}"
    end
  end
  
  def registered?(rule);  @grammar[rule.name]     end
  def start_rule;         @grammar[@start_symbol] end
end

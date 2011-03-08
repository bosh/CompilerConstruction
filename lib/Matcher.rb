class Matcher
  attr_accessor :text, :type

  def initialize(text, type)
    @text = text
    @type = type
  end

  def match?(tokenstream)
    token      =  tokenstream[$current_index]
    if   @type == :literal
      if @text == token.value;
        advance_index!
        Node.new(token)
      else
        matcher_unsuccessful(:literal_mismatch)
      end
    elsif @type == :type
      if @text.downcase == token.type.downcase #NOTE case insensitive
        advance_index!
        Node.new(token)
      else
        matcher_unsuccessful(:type_mismatch)
      end
    elsif @type == :metasymbol
      rule   = $parser.grammar.grammar[text]
      puts   "recurse to #{rule.name}" if debug?
      result = rule.match?(tokenstream)
      if result.valid?
        result #should already be a node
      else
        matcher_unsuccessful(:subrule_mismatch)
      end
    end
  end

  def to_s;                       "Matcher: #{@text},\t#{@type}"                      end
  def to_extended;                to_s                                                end
  def advance_index!;             puts $current_index if debug?; $current_index += 1  end
  def matcher_unsuccessful(how);  Node.new("Error: #{how.to_s}")                      end
end

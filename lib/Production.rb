class Production
  attr_accessor :text, :subproductions

  def initialize(text)
    @text           = text.strip
    @subproductions = []
    create_subproductions
  end

  def create_subproductions
    until @text.empty? : @subproductions << subproduce_next_metasymbol end
  end

  def subproduce_next_metasymbol
    type = nil
    case @text
      when /\A"(.*?)"/    : type = :literal
      when /\A([a-z]\w*)/ : type = :type
      when /\A([A-Z]\w*)/ : type = :metasymbol
      when /\A(\[.*?\])/  : type = :optional
      when /\A(\{.*?\})/  : type = :repeating
      when /\A(\(.*?\))/  : type = :choice #Perhaps should be multiline (should all be?)
      else
        puts "FATAL ERROR IN METASYMBOL ANALYSIS: #{@text}"
    end
    sub_text  = $1
    @text     = @text[(sub_text.length + ((type == :literal)? 2 : 0))..-1].strip
    create_matcher(sub_text, type)
  end

  def create_matcher(text, type)
    if [:optional, :repeating, :choice].include? type
      Rule.new("anonymous", text)
    else
      Matcher.new(text, type)
    end
  end

  def match?(tokenstream)
    matches = []
    @subproductions.each do |s|
      match = s.match?(tokenstream)
      if match.valid?
        matches << match
      else
        return production_unsuccessful
      end
    end
    Node.new("Production", nil, matches)
  end

  def production_unsuccessful
    puts "production unsuccessful" if debug?
    Node.new("Fatal error: production unsuccessful")
  end


  def to_s; "Subproduction: #{@subproductions.size} submatchers" end
  def to_extended
    str = to_s
    @subproductions.each{|s| str << "\n\t\t#{s.to_extended}"}
    str
  end
end

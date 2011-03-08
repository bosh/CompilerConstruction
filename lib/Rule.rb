class Rule
  attr_accessor :name, :text, :productions, :type

  def initialize( name, text )
    @name         = name.strip
    @text         = text.strip
    @productions  = []
    @type = :basic #The only nonbasics are opt/repeating
    create_productions
  end

  def to_s; "Rule: #{@name}, #{@type}, #{@productions.size} top level productions"  end
  def create_productions; identify_productions.each{ |p| add_production(p) }        end
  def add_production(text); @productions << Production.new(text) end
  def combine_repeating(matches); Node.new("Repeater node", nil, matches) end
  def empty_match; Node.new("Empty match") end
  def rule_unsuccessful; Node.new("Error: Rule unsuccessful") end

  def to_extended
    str = to_s
    @productions.each{|p| str << "\n\t#{p.to_extended}"}
    str
  end

  def identify_productions
    prods = []
    if @text.wrapped?("(", ")") #Major limitation, there may not be different option sets in a rule at the same level/depth
      choice_productions.each{|p| prods << p}
    elsif @text.wrapped?("{", "}") #Major limitation again, no starting and ending with different option blocks
      @type =   :repeating
      prods <<  @text[1...-1].strip
    elsif @text.wrapped?("[", "]") #Major limitation again, no starting and ending with different option blocks
      @type =   :optional
      prods <<  @text[1...-1].strip
    else
      prods <<  @text
    end
    prods
  end

  def choice_productions
    subs = @text[1...-1].strip
    subs.gsub!("/", "//") #Major limitation, in that rules with /'s cannot have literal /'s
    subs.scan(/(\A|\/)(.*?)(\z|\/)/m).map{|i| i[1]}
  end

  def match?(tokenstream)
    $matchno += 1
    matchnum = $matchno
    puts "#{matchnum}  starting a match at #{$current_index} :: #{@type}" if debug?
    entry_position = $current_index
    match = nil
    if    @type == :basic
      if  @productions.size > 1 #it's a choice rule
        @productions.each do |p|
          match = p.match?(tokenstream)
          if match.valid?
            break
          else
            $current_index = entry_position
          end
        end
      else #it's a single production rule
        match = @productions.first.match?(tokenstream)
      end
      if !match.valid?
        $current_index = entry_position
        match = rule_unsuccessful
      end
    elsif @type == :repeating
      reps = []
      until match && !match.valid?
        entry_position = $current_index
        if match #so it skips on first runthrough
          reps << match #save off a valid match (ie it wont on the nil case)
          entry_position = $current_index
        end
        match = @productions.first.match?(tokenstream)
      end
      $current_index = entry_position #takes the entry_position of the last rep
      if reps.size > 0
        match = combine_repeating(reps) #takes array, returns node
      else
        match = empty_match #fail case
      end
    elsif @type == :optional
      match = @productions.first.match?(tokenstream)
      unless match.valid?
        $current_index = entry_position
        match = empty_match #fail case
      end
    else
      puts "Rule type #{@type} was not recognized. Terminating simParse"
      exit(0)
    end
    puts "#{matchnum}  closed the match at #{$current_index}" if debug?
    if match.content == "Production" : match.content = "Rule: #{@name}" end
    match #return
  end
end

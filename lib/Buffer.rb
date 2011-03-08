class Buffer
  attr_accessor :contents, :current, :current_head, :style
  def initialize(str, dirty = false, style = :default)
    @contents = str.strip
    @current  = @current_head = 0
    @style    = style
    clean! unless dirty #Heh heh heh
  end
  
  def clean!;       @contents.gsub!(/\{.*?(\}|\z)/m, "")  end #Strip {} comments
  def finished?;    @current_head >= @contents.length     end
  def advance;      @current += 1                         end
  def back_up;      @current -= 1                         end
  def update_head;  @current_head = @current              end
  
  def lookahead #Returns the character one ahead of the lookahead
    if @current+1 < @contents.size
      Token.new(@contents[@current+1,1]) #token so that it can call the _? methods
    else
      nil
    end
  end

  def get_next_token
    if finished? : return nil end #Returns a nil if past end and still being called
    token     = Token.new("")
    @current  = @current_head #make certain that current == head to start with
    token << @contents[@current, 1]
    if token.quote?
      advance until (lookahead == nil || lookahead.quote?)
      advance
      text    = @contents[@current_head..@current]
      token   = Token.new(text, "LITERAL", text)
      advance #should be right
      update_head
    elsif token.digit?
      advance while lookahead && lookahead.digit?
      if lookahead && lookahead.identifier_tail? #if it's a nonterminal that is also a nondigit
        text  = @contents[@current_head..@current]
        update_head
        puts "INT Token: #{text} is followed by nondigits (#{lookahead.text}). Terminating run."
        exit(0)
      end
      text    = @contents[@current_head..@current]
      token   = Token.new(text, "INT", text)
      advance #should be right
      update_head
    elsif token.identifier_head?
      advance while lookahead && lookahead.identifier_tail?
      text    = @contents[@current_head..@current]
      token   = Token.new(text, "ID", text)
      advance #this bit might be factorable too.. what about token.assemble or something
      update_head
    elsif token.symbol?
      if lookahead && Token.new(token << lookahead.text).symbol? : advance end
      text    = @contents[@current_head..@current]
      token   = Token.new(text, "SYMBOL", text)
      advance
      update_head
    elsif token.whitespace?
      advance while lookahead && lookahead.whitespace?
      advance
      update_head
      token   = get_next_token #recursion, not great, but should be impossible to get more than one level deep
    else
      puts "Token: #{token.text} was not recognized as valid. Terminating run."
      exit(0)
    end
    token
  end
end

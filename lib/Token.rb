class Token
  attr_accessor :text, :type, :value

  @@keywords = %w(
    and     begin  forward   div  do     else
    end     for    function  if   array  mod
    not     of     or        procedure   program
    record  then   to        type        var      while
  )
  @@symbols = %w( + * -   =   < <=  > >=  <>  . , : ; :=  ..  ( ) [ ] )
  @@relops  = %w( = < <=  >=  > <>  )
  @@ariths  = %w( + * -             )
  @@groups  = %w( ( ) [   ]         )
  
  def initialize(text, type = "", value = "")
    @text   = text
    @type   = type
    @value  = value
    specify_type!
  end

  def specify_type!
    if      keyword?          : @type = "KEYWORD"
      elsif string_literal?   : @type = "STR"
      elsif relational_op?    : @type = "RELOP"
      elsif arithmetic_op?    : @type = "ARITHOP"
      elsif grouping_symbol?  : @type = "GROUP"
    end
  end
  
  def to_terminal;        @value  end
  def to_s;               "#{@type}|#{@value}"      end
  def << (str);           @text << str              end
  def grouping_symbol?;   @@groups.index(   @text ) end
  def relational_op?;     @@relops.index(   @text ) end
  def arithmetic_op?;     @@ariths.index(   @text ) end
  def keyword?;           @@keywords.index  @text   end
  def symbol?;            @@symbols.index   @text   end
  def string_literal?;    @text.match( /\A\".*\"\z/m )        end
  def identifier_head?;   @text.match( /\A[a-zA-Z]\z/ )       end
  def identifier_tail?;   @text.match( /\A[a-zA-Z0-9_]*\z/ )  end
  def digit?;             @text.match( /\A[0-9]+\z/ )         end
  def quote?;             @text.match( /\A"\z/ )              end
  def whitespace?;        @text.match( /\A[\n\t\ ]*\z/ )      end
  
  def tokenized(style = :default)
    if      style == :default   : "#{@type} #{@value}\n"
      elsif style == :brackets  : "[#{@type}: #{@value}]\n"
      elsif style == :indent    : "\t#{@type}: #{@value}\n"
      elsif style == :angle     : "<#{@type}, #{@value}>\n"
    end
  end
end

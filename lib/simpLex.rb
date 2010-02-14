#But first, a short: Lolbuzz
#(1..100).each{|i| puts((i%3==0) ? ((i%5==0)? "fizzbuzz" : "fizz" ) : ((i%5==0)? "buzz" : i) )}

class Lexer
  attr_accessor :buffer
  def initialize()
    load_buffer
  end
  def load_buffer
    @buffer = "simple buffer"
  end
end
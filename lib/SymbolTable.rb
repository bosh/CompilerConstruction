class SymbolTable
  attr_accessor :members, :scope, :subtables
  def initialize(scope)
    @scope = scope
    @members = {}
    @subtables = []
  end
  
  def add_variable(var, type = true)
    if already_defined?(var)
      puts "Error, #{var} already defined in scope #{@scope}"
    else
      @members[var] = type
    end
  end

  def add_subtable(sub); @subtables << sub end
  def already_defined?(var); contains?(var)end#||global_contains?(var) end #sorta fake
  def global_contains?(var); $parser.symbol_table.contains?(var) end
  def contains?(var); @members[var] end
  def to_s; "#{@scope}: #{@members}\t#{@subtables}"end
end

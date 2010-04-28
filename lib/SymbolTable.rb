class SymbolTable
  attr_accessor :members, :scope, :subtables
  def initialize(scope)
    @scope = scope
    @members = {}
    @subtables = []
  end
  
  def add_variable(var)
    if already_defined?(var)
      false #TODO: caller rec's a false, should blow up there. or could blow up here. whichever
    else
      @members[var] = true
      true
    end
  end

  def add_subtable(sub); @subtables << sub end
  def already_defined?(var); contains?(var)||global_contains?(var) end #sorta fake
  def global_contains?(var); $parser.symbol_table.contains?(var) end
  def contains?(var); @members[var] end
  def to_s; "#{@scope}: #{@members}\t#{@subtables}"end
end
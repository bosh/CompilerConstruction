class SymbolTable
  attr_accessor :members, :types, :scope, :subtables
  def initialize(scope)
    @scope =      scope
    @members =    {}
    @types =      {}
    @subtables =  []
  end
  
  def add_variable(var, type = true)
    if already_defined?(var)
      puts "Error, #{var} already defined in scope #{@scope}"
    else
      @members[var] = type
    end
  end

  def add_type(var, type)
    if already_defined_type?(var)
      puts "Error, #{var} already defined in scope #{@scope}"
    else
      @types[var] = type
    end
  end

  def add_subtable(sub);          @subtables << sub end
  def already_defined?(var);      contains?(var) end# || global_contains?(var) end #sorta fake
  def already_defined_type?(var); contains_type?(var) end #||global_contains?(var) end #sorta fake
  def global_contains?(var);      $parser.symbol_table.contains?(var) end
  def contains?(var);             @members[var] end
  def contains_type?(var);        @types[var] end

  def to_s
    str = "Scope: #{@scope}:\nTypes:\n"
    @types.each{ |k, v|   str << "  #{k} #{v}\n" }
    str << "Members:\n"
    @members.each{ |k, v| str << "  #{k} #{v}\n" }
    str << "Subtables:\n"
    @subtables.each{ |s|  str << "#{s}\n\n" }
    str
  end
end

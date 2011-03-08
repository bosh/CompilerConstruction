class String
  #delimiters, currently only single-character valid
  def wrapped?( open, close = open ); self[0,1] == open && self[-1,1] == close end

  def dequote!; replace( dequote ) end

  def quoted?( style = :both )
    if wrapped?(        "'" )   || wrapped?( '"' )
      if style    ==    :single
        self[0,1] ==    "'"
      elsif style ==    :double
        self[0,1] ==    '"'
      else #both or an unrecognized, which defaults to both
        self[0,1] ==    '"'     || self[0,1] == "'"
      end
    else
      false
    end
  end

  #removes matched quotes and strips whitespace
  def dequote
    if self.quoted?
      return self[1...-1].strip
    else
      return self #TODO or should this be a false/nil/error?
    end
  end
end
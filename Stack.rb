class Stack < Array
  def initialize
    @programindex = 0
    @continueprogram = true

    @eaten = [] # Debug values
  end

  def viewlunch
    @eaten
  end

  def eat(program)

    while (@continueprogram)
      code = program[@programindex]
      @eaten << [@programindex, code]

      if @programindex >= program.length || @programindex < 0
        warn "Unexpected end of program, out of programbound!"
        p @eaten
        return self
      end

      @programindex += 1

      if code.class == Symbol
        self.method(code).call
      else # not a funciton call push value to stack
        self << code
      end
    end
    self
  end

  def reset
    self.clear
    @eaten.clear
    @programindex = 0
    @continueprogram = true
  end

  def plus
    right, left = pop, pop
    self << (left + right)
  end

  def minus
    right, left = pop, pop
    self << (left - right)
  end

  def multiply
    right, left = pop, pop
    self << (left * right)
  end

  def divide
    right, left = pop, pop
    self << (left / right)
  end

  def assign
    value, index = pop, pop
    self[size - index - 1] = value
  end

  def duplicate
    index = pop
    value = self[size-index-1]
    self << value
  end

  def less
    right, left = pop, pop
    self << (left < right)
  end

  def equals
	  p @programindex
    right, left = pop, pop
    self << (left == right)
  end

  def goto
     address = pop
     @programindex = address
  end

  def if
    truthvalue, address = pop, pop
    if not truthvalue then
      self << address
      goto
    end
  end

  def print
    value = pop
    puts value
  end

  def swap
    value1, value2 = pop, pop
    self << value1 << value2
  end

  def true
    self << true
  end

  def false
    self << false
  end

  def exit
    @continueprogram = false
  end

end

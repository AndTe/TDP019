class Stack < Hash
  def initialize
    @programindex = 0
    @continueprogram = true
    @stackindex = 0
    @heapindex = 0
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
      else # not a function call push value to stack
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
    @stackindex = 0
    @heapindex = 0
  end

  def << (value)
    @stackindex += 1
    self[@stackindex] = value
    self
  end

  def popStack
    value = self.delete(@stackindex)
    @stackindex -= 1
    value
  end

  def stacktop
    self << @stackindex
  end

  def pop
    value = popStack
    while (value > 0)
      popStack
      value -= 1
    end
  end

  def plus
    right, left = popStack, popStack
    self << (left + right)
  end

  def minus
    right, left = popStack, popStack
    self << (left - right)
  end

  def multiply
    right, left = popStack, popStack
    self << (left * right)
  end

  def divide
    right, left = popStack, popStack
    self << (left / right)
  end

  def less
    right, left = popStack, popStack
    self << (left < right)
  end

  def equals
	  p @programindex
    right, left = popStack, popStack
    self << (left == right)
  end

  def goto
     address = popStack
     @programindex = address
  end

  def if
    truthvalue, address = popStack, popStack
    if not truthvalue then
      self << address
      goto
    end
  end

  def swap
    value1, value2 = popStack, popStack
    self << value1 << value2
  end

  def exit
    @continueprogram = false
  end

  def reference_block(blocksize)
    to = @heapindex - 1
    @heapindex -= blocksize
    for i in (@heapindex..to)
      self[i] = nil
    end
    @heapindex
  end

  # references
  def reference
    blocksize = popStack
    self << reference_block(blocksize)
  end

  def assign_to_reference
    value, ref = popStack, popStack
    self[ref] = value
  end

  def reference_value
    ref = popStack
    self << self[ref]
  end

  def delete_reference
    ref = popStack
    self.delete(ref)
  end

  # boolean operators
  def and
    value1, value2 = popStack, popStack
    self << (value2 and value1)
  end

  def or
    value1, value2 = popStack, popStack
    self << (value2 or value1)
  end

  def not
    value = popStack
    self << (not value)
  end

  def input
    self << getc
  end

  def output
    asciiValue = popStack
    print asciiValue.chr
  end
end

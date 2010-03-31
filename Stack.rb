class Stack < Array
  def initialize
    @programindex = 0
    @continueprogram = true
    @heap = {}
    @heapindex = 1
    @eaten = [] # Debug values
  end

  def viewlunch
    @eaten
  end

  def heap
    @heap
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
    @heap.clear
    @heapindex = 1
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
    self[-1 - index] = value
  end

  def duplicate
    index = pop
    value = self[-1 - index]
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

  def reference_block(blocksize)
    first = @heapindex
    @heapindex += blocksize
    (@heapindex - 1).downto(first) { | i |
      @heap[i] = nil
    }
    first
  end

  # references
  def reference
    blocksize = pop
    self << reference_block(blocksize)
  end

  def assign_to_reference
    value, ref = pop, pop
    heap[ref] = value
  end

  def reference_value
    ref = pop
    self << @heap[ref]
  end

  def delete_reference
    ref = pop
    @heap.delete(ref)
  end
end

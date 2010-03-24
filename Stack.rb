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

      if code.class == Method
        code.call
      else # not a funciton call push value to stack
        self << code
      end
    end
    self
  end

  def plus
    self << pop + pop
  end

  def minus
    right, left = pop, pop
    self << left - right
  end

  def less
    right, left = pop, pop
    self << left < right
  end

  def lessequals
    right, left = pop, pop
    self << left <= right
  end

  def equals
    right, left = pop, pop
    self << left == right
  end

  def exit
    @continueprogram = false
  end

end

engine = Stack.new
postfixSource = "1 2 + exit"
#program = readPostfixSource(postfixSource)
program = [1,2, engine.method(:plus), engine.method(:exit)]
p engine
p program
#engine.eat(program)

require 'test/unit'
require 'Stack.rb'
require 'PostfixParser.rb'

class Test_Stack < Test::Unit::TestCase
  def setup
    @engine = Stack.new
  end


  def exit
    @engine.clear
    program = readPostfixSource("1 exit 2")
    @engine.eat(program)
    assert(@engine, [1])
  end

  def plus
    @engine.clear
    program = readPostfixSource("1 3 + exit")
    @engine.eat(program)
    assert(@engine, [4])
  end

  def minus
    @engine.clear
    program = readPostfixSource("1 3 - exit")
    @engine.eat(program)
    assert(@engine, [-2])
  end

  def multiply
    @engine.clear
    program = readPostfixSource("13 3 * exit")
    @engine.eat(program)
    assert(@engine, [39])
  end

  def divide
    @engine.clear
    program = readPostfixSource("9 3 / exit")
    @engine.eat(program)
    assert(@engine, [3])
  end

  def less
    @engine.clear
    program = readPostfixSource("9 3 < exit")
    @engine.eat(program)
    assert(@engine, [false])

    @engine.clear
    program = readPostfixSource("3 3 < exit")
    @engine.eat(program)
    assert(@engine, [false])

    @engine.clear
    program = readPostfixSource("2 3 < exit")
    @engine.eat(program)
    assert(@engine, [true])
  end

  def lessequals
    @engine.clear
    program = readPostfixSource("9 3 <= exit")
    @engine.eat(program)
    assert(@engine, [false])

    @engine.clear
    program = readPostfixSource("3 3 <= exit")
    @engine.eat(program)
    assert(@engine, [true])

    @engine.clear
    program = readPostfixSource("2 3 <= exit")
    @engine.eat(program)
    assert(@engine, [true])
  end

  def equals
    @engine.clear
    program = readPostfixSource("9 3 == exit")
    @engine.eat(program)
    assert(@engine, [false])

    @engine.clear
    program = readPostfixSource("3 3 == exit")
    @engine.eat(program)
    assert(@engine, [true])

    @engine.clear
    program = readPostfixSource("2 3 == exit")
    @engine.eat(program)
    assert(@engine, [false])
  end

  def assign
    @engine.clear
    program = readPostfixSource("1 1 1 2 = exit")
    @engine.eat(program)
    assert(@engine, [2, 1])
  end

  def duplicate
    @engine.clear
    program = readPostfixSource("42 duplicate exit")
    @engine.eat(program)
    assert(@engine, [42, 42])
  end

  def goto
    @engine.clear
    program = readPostfixSource("0 1 5 goto 10 2 3 exit")
    @engine.eat(program)
    lunch = @engine.viewlunch.collect {| el | el[1]}
    assert(@engine, [0, 1, 2, 3])
    assert(lunch, [0, 1, 5, :goto, 2, 3, :exit])
  end

  def if
    @engine.clear
    program = readPostfixSource("4 true if 10 11 exit")
    @engine.eat(program)
    lunch = @engine.viewlunch.collect {| el | el[1]}
    assert(@engine, [10, 11])
    assert(viewlunch, [0, 1, 5, :goto, 2, 3, :exit])

    @engine.clear
    program = readPostfixSource("4 false if 10 11 exit")
    lunch = @engine.viewlunch.collect {| el | el[1]}
    @engine.eat(program)
    assert(@engine, [11])
    assert(viewlunch, [4, false, :if, 11, :exit])
  end

  def print
    @engine.clear
    program = readPostfixSource("1 42 print 2 exit")
    @engine.eat(program)
    assert(@engine, [1, 2])
  end

  def swap
    @engine.clear
    program = readPostfixSource("1 3 2 swap 4 exit")
    @engine.eat(program)
    assert(@engine, [1, 2, 3, 4])
  end

  def pop
    @engine.clear
    program = readPostfixSource("1 3 pop 2 4 pop 3 4 exit")
    @engine.eat(program)
    assert(@engine, [1, 2, 3, 4])
  end
end

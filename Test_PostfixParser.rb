require 'test/unit'
require 'Stack.rb'
require 'PostfixParser.rb'

class Test_PostfixParser < Test::Unit::TestCase
  def exit
    program = PostfixParseString("exit")
    assert(program, [:exit])
  end

  def plus
    program = PostfixParseString("+")
    assert(program, [:plus])
  end

  def minus
    program = PostfixParseString("-")
    assert(program, [:minus])
  end

  def multiply
    program = PostfixParseString("*")
    assert(program, [:multiply])
  end

  def divide
    program = PostfixParseString("/")
    assert(program, [:divide])
  end

  def less
    program = PostfixParseString("<")
    assert(program, [:less])
  end

  def lessequals
    program = PostfixParseString("<=")
    assert(program, [:lessequals])
  end

  def equals
    program = PostfixParseString("==")
    assert(program, [:equals])
  end

  def assign
    program = PostfixParseString("=")
    assert(program, [:assign])
  end

  def duplicate
    program = PostfixParseString("duplicate")
    assert(program, [:duplicate])
  end

  def goto
    program = PostfixParseString("goto")
    assert(program, [:goto])
  end

  def if
    program = PostfixParseString("if")
    assert(program, [:if])
  end

  def print
    program = PostfixParseString("print")
    assert(program, [:print])
  end

  def swap
    program = PostfixParseString("swap")
    assert(program, [:swap])
  end

  def pop
    program = PostfixParseString("pop")
    assert(program, [:pop])
  end

  def PostfixParseFile
    program = PostfixParseFile("test_postfixsource.pf")
    assert(program, [7, 4, 3, :less, :if, 1, 3, 2, :swap, :exit])
  end

  def comments
    program = PostfixParseString("1(comment 1) 3 swap(comment 2, comment 3) exit (comment4)")
    assert(program, [1, 3, :swap, :exit])

    program = PostfixParseStringDebug("1(comment 1) 3 swap(comment 2, comment 3) exit (comment4)")
    assert(program, [[1, "comment 0"], [3, nil], [:swap, "comment 2, comment 3"], [:exit, "comment4"]])
  end
end

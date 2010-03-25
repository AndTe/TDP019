require 'test/unit'
require 'Stack.rb'
require 'PostfixParser.rb'

class Test_Stack < Test::Unit::TestCase
  def setup
    @engine = Stack.new
  end


  def test_exit
    @engine.clear
    program = PostfixParseString("1 exit 2")
    @engine.eat(program)
    assert_equal(@engine, [1])
  end

  def test_plus
    @engine.clear
    program = PostfixParseString("1 3 + exit")
    @engine.eat(program)
    assert_equal(@engine, [4])
  end

  def test_minus
    @engine.clear
    program = PostfixParseString("1 3 - exit")
    @engine.eat(program)
    assert_equal(@engine, [-2])
  end

  def test_multiply
    @engine.clear
    program = PostfixParseString("13 3 * exit")
    @engine.eat(program)
    assert_equal(@engine, [39])
  end

  def test_divide
    @engine.clear
    program = PostfixParseString("9 3 / exit")
    @engine.eat(program)
    assert_equal(@engine, [3])
  end

  def test_less
    @engine.reset
    program = PostfixParseString("9 3 < exit")
    @engine.eat(program)
    assert_equal(@engine, [false])

    @engine.reset
    program = PostfixParseString("3 3 < exit")
    @engine.eat(program)
    assert_equal(@engine, [false])

    @engine.reset
    program = PostfixParseString("2 3 < exit")
    @engine.eat(program)
    assert_equal(@engine, [true])
  end

  def test_equals
    @engine.reset
    program = PostfixParseString("9 3 == exit")
    @engine.eat(program)
    assert_equal(@engine, [false])

    @engine.reset
    program = PostfixParseString("3 3 == exit")
    @engine.eat(program)
    p program
    p @engine.viewlunch
    assert_equal(@engine, [true])

    @engine.reset
    program = PostfixParseString("2 3 == exit")
    @engine.eat(program)
    assert_equal(@engine, [false])
  end

  def test_assign
    @engine.clear
    p @engine
    program = PostfixParseString("1 1 1 2 = exit")
    @engine.eat(program)
    assert_equal(@engine, [2, 1])
  end

  def test_duplicate
    @engine.clear
    program = PostfixParseString("42 0 duplicate exit")
    @engine.eat(program)
    assert_equal(@engine, [42, 42])
  end

  def test_goto
    @engine.clear
    program = PostfixParseString("0 1 5 goto 10 2 3 exit")
    @engine.eat(program)
    lunch = @engine.viewlunch.collect {| el | el[1]}
    assert_equal(@engine, [0, 1, 2, 3])
    assert_equal(lunch, [0, 1, 5, :goto, 2, 3, :exit])
  end

  def test_if
    @engine.reset
    program = PostfixParseString("4 true if 10 11 exit")
    @engine.eat(program)
    lunch = @engine.viewlunch.collect {| el | el[1]}
    assert_equal(@engine, [10, 11])
    assert_equal(lunch, [4, true, :if, 10, 11, :exit])

    @engine.reset
    program = PostfixParseString("4 false if 10 11 exit")
    lunch = @engine.viewlunch.collect {| el | el[1]}
    @engine.eat(program)
    assert_equal(@engine, [11])
    assert_equal(lunch, [4, false, :if, 11, :exit])
  end

  def test_print
    @engine.clear
    program = PostfixParseString("1 42 print 2 exit")
    @engine.eat(program)
    assert_equal(@engine, [1, 2])
  end

  def test_swap
    @engine.clear
    program = PostfixParseString("1 3 2 swap 4 exit")
    @engine.eat(program)
    assert_equal(@engine, [1, 2, 3, 4])
  end

  def test_pop
    @engine.clear
    program = PostfixParseString("1 3 pop 2 4 pop 3 4 exit")
    @engine.eat(program)
    assert_equal(@engine, [1, 2, 3, 4])
  end
end

require 'test/unit'
require 'Stack.rb'
require 'PostfixParser.rb'

class Test_Stack < Test::Unit::TestCase
  def setup
    @engine = Stack.new
  end


  def test_exit
    @engine.reset
    program = PostfixParseString("1 exit 2")
    @engine.eat(program)
    assert_equal([1], @engine)
  end

  def test_plus
    @engine.reset
    program = PostfixParseString("1 3 + exit")
    @engine.eat(program)
    assert_equal([4], @engine)
  end

  def test_minus
    @engine.reset
    program = PostfixParseString("1 3 - exit")
    @engine.eat(program)
    assert_equal([-2], @engine)
  end

  def test_multiply
    @engine.reset
    program = PostfixParseString("13 3 * exit")
    @engine.eat(program)
    assert_equal([39], @engine)
  end

  def test_divide
    @engine.reset
    program = PostfixParseString("9 3 / exit")
    @engine.eat(program)
    assert_equal([3], @engine)
  end

  def test_less
    @engine.reset
    program = PostfixParseString("9 3 < exit")
    @engine.eat(program)
    assert_equal([false], @engine)

    @engine.reset
    program = PostfixParseString("3 3 < exit")
    @engine.eat(program)
    assert_equal([false], @engine)

    @engine.reset
    program = PostfixParseString("2 3 < exit")
    @engine.eat(program)
    assert_equal([true], @engine)
  end

  def test_equals
    @engine.reset
    program = PostfixParseString("9 3 == exit")
    @engine.eat(program)
    assert_equal([false], @engine)

    @engine.reset
    program = PostfixParseString("3 3 == exit")
    @engine.eat(program)
    p program
    p @engine.viewlunch
    assert_equal([true], @engine)

    @engine.reset
    program = PostfixParseString("2 3 == exit")
    @engine.eat(program)
    assert_equal([false], @engine)
  end

  def test_assign
    @engine.reset
    p @engine
    program = PostfixParseString("1 1 1 2 = exit")
    @engine.eat(program)
    assert_equal([2, 1], @engine)
  end

  def test_duplicate
    @engine.reset
    program = PostfixParseString("42 0 duplicate exit")
    @engine.eat(program)
    assert_equal([42, 42], @engine)
  end

  def test_goto
    @engine.reset
    program = PostfixParseString("0 1 5 goto 10 2 3 exit")
    @engine.eat(program)
    lunch = @engine.viewlunch.collect {| el | el[1]}
    assert_equal([0, 1, 2, 3], @engine)
    assert_equal([0, 1, 5, :goto, 2, 3, :exit], lunch)
  end

  def test_if
    @engine.reset
    program = PostfixParseString("4 true if 10 11 exit")
    @engine.eat(program)
    lunch = @engine.viewlunch.collect {| el | el[1]}
    assert_equal([10, 11], @engine)
    assert_equal([4, true, :if, 10, 11, :exit], lunch)

    @engine.reset
    program = PostfixParseString("4 false if 10 11 exit")
    @engine.eat(program)
    lunch = @engine.viewlunch.collect {| el | el[1]}
    assert_equal([11], @engine)
    assert_equal([4, false, :if, 11, :exit], lunch)
  end

  def test_print
    @engine.reset
    program = PostfixParseString("1 42 print 2 exit")
    @engine.eat(program)
    assert_equal([1, 2], @engine)
  end

  def test_swap
    @engine.reset
    program = PostfixParseString("1 3 2 swap 4 exit")
    @engine.eat(program)
    assert_equal([1, 2, 3, 4], @engine)
  end

  def test_pop
    @engine.reset
    program = PostfixParseString("1 3 pop 2 4 pop 3 4 exit")
    @engine.eat(program)
    assert_equal([1, 2, 3, 4], @engine)
  end

  def test_reference
    @engine.reset
    program = PostfixParseString("1 reference")
    @engine.eat(program)
    assert_equal([1], @engine)
    assert_equal({1 => nil}, @engine.heap)

    @engine.reset
    program = PostfixParseString("1 reference 2 reference")
    @engine.eat(program)
    assert_equal([1, 2], @engine)
    assert_equal({1 => nil, 2 => nil, 3 => nil}, @engine.heap)

    @engine.reset
    program = PostfixParseString("2 reference 1 reference")
    @engine.eat(program)
    assert_equal([1, 3], @engine)
    assert_equal({1 => nil, 2 => nil, 3 => nil}, @engine.heap)
  end

  def test_assign_to_reference
    @engine.reset
    program = PostfixParseString("1 reference 100 assign_to_reference")
    @engine.eat(program)
    assert_equal([], @engine)
    assert_equal({1 => 100}, @engine.heap)

    @engine.reset
    program = PostfixParseString("2 reference 1 + 100 assign_to_reference")
    @engine.eat(program)
    assert_equal([], @engine)
    assert_equal({1 => nil, 2 => 100}, @engine.heap)
  end

  def test_reference_value
    @engine.reset
    program = PostfixParseString("1 reference 0 duplicate 100 assign_to_reference reference_value")
    @engine.eat(program)
    assert_equal([100], @engine)
    assert_equal({1 => 100}, @engine.heap)

    @engine.reset
    program = PostfixParseString("2 reference 1 + 0 duplicate 100 assign_to_reference reference_value")
    @engine.eat(program)
    assert_equal([100], @engine)
    assert_equal({1 => nil, 2 => 100}, @engine.heap)
  end

  def test_delete_reference
    @engine.reset
    program = PostfixParseString("1 reference 0 duplicate 100 assign_to_reference delete_reference")
    @engine.eat(program)
    assert_equal([], @engine)
    assert_equal({}, @engine.heap)

    @engine.reset
    program = PostfixParseString("2 reference 0 duplicate 1 + delete_reference delete_reference")
    @engine.eat(program)
    assert_equal([], @engine)
    assert_equal({}, @engine.heap)
  end

  def test_and
    @engine.reset
    program = PostfixParseString("false false and")
    @engine.eat(program)
    assert_equal([false], @engine)

    @engine.reset
    program = PostfixParseString("false true and")
    @engine.eat(program)
    assert_equal([false], @engine)

    @engine.reset
    program = PostfixParseString("true false and")
    @engine.eat(program)
    assert_equal([false], @engine)

    @engine.reset
    program = PostfixParseString("true true and")
    @engine.eat(program)
    assert_equal([true], @engine)
  end

  def test_or
    @engine.reset
    program = PostfixParseString("false false or")
    @engine.eat(program)
    assert_equal([false], @engine)

    @engine.reset
    program = PostfixParseString("false true or")
    @engine.eat(program)
    assert_equal([true], @engine)

    @engine.reset
    program = PostfixParseString("true false or")
    @engine.eat(program)
    assert_equal([true], @engine)

    @engine.reset
    program = PostfixParseString("true true or")
    @engine.eat(program)
    assert_equal([true], @engine)
  end

  def test_not
    @engine.reset
    program = PostfixParseString("false not")
    @engine.eat(program)
    assert_equal([true], @engine)

    @engine.reset
    program = PostfixParseString("true not")
    @engine.eat(program)
    assert_equal([false], @engine)
  end

end

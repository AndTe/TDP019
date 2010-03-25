require 'test/unit'
require 'Stack.rb'
require 'PostfixParser.rb'

class Test_PostfixParser < Test::Unit::TestCase
  def test_exit
    program = PostfixParseString("exit")
    assert_equal(program, [:exit])
  end

  def test_plus
    program = PostfixParseString("+")
    assert_equal(program, [:plus])
  end

  def test_minus
    program = PostfixParseString("-")
    assert_equal(program, [:minus])
  end

  def test_multiply
    program = PostfixParseString("*")
    assert_equal(program, [:multiply])
  end

  def test_divide
    program = PostfixParseString("/")
    assert_equal(program, [:divide])
  end

  def test_less
    program = PostfixParseString("<")
    assert_equal(program, [:less])
  end

  #~ def test_lessequal
    #~ program = PostfixParseString("<=")
    #~ assert_equal(program, [:operator_<=])
  #~ end

  def test_equal
    program = PostfixParseString("==")
    assert_equal(program, [:equals])
  end

  def test_assign
    program = PostfixParseString("=")
    assert_equal(program, [:assign])
  end

  def test_duplicate
    program = PostfixParseString("duplicate")
    assert_equal(program, [:duplicate])
  end

  def test_goto
    program = PostfixParseString("goto")
    assert_equal(program, [:goto])
  end

  def test_if
    program = PostfixParseString("if")
    assert_equal(program, [:if])
  end

  def test_print
    program = PostfixParseString("print")
    assert_equal(program, [:print])
  end

  def test_swap
    program = PostfixParseString("swap")
    assert_equal(program, [:swap])
  end

  def test_pop
    program = PostfixParseString("pop")
    assert_equal(program, [:pop])
  end

  #~ def PostfixParseFile
    #~ program = PostfixParseFile("test_postfixsource.pf")
    #~ assert_equal(program, [7, 4, 3, :less, :if, 1, 3, 2, :swap, :exit])
  #~ end

  #~ def comments
    #~ program = PostfixParseString("1(comment 1) 3 swap(comment 2, comment 3) exit (comment4)")
    #~ assert_equal(program, [1, 3, :swap, :exit])

    #~ program = PostfixParseStringDebug("1(comment 1) 3 swap(comment 2, comment 3) exit (comment4)")
    #~ assert_equal(program, [[1, "comment 0"], [3, nil], [:swap, "comment 2, comment 3"], [:exit, "comment4"]])
  #~ end
end

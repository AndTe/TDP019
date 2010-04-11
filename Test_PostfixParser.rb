require 'test/unit'
require 'Stack.rb'
require 'PostfixParser.rb'

class Test_PostfixParser < Test::Unit::TestCase
  def test_exit
    program = PostfixParseString("exit")
    assert_equal([:exit], program)
  end

  def test_plus
    program = PostfixParseString("+")
    assert_equal([:plus], program)
  end

  def test_minus
    program = PostfixParseString("-")
    assert_equal([:minus], program)
  end

  def test_multiply
    program = PostfixParseString("*")
    assert_equal([:multiply], program)
  end

  def test_divide
    program = PostfixParseString("/")
    assert_equal([:divide], program)
  end

  def test_less
    program = PostfixParseString("<")
    assert_equal([:less], program)
  end

  def test_equal
    program = PostfixParseString("==")
    assert_equal([:equals], program)
  end

  def test_goto
    program = PostfixParseString("goto")
    assert_equal([:goto], program)
  end

  def test_if
    program = PostfixParseString("if")
    assert_equal([:if], program)
  end

  def test_print
    program = PostfixParseString("print")
    assert_equal([:print], program)
  end

  def test_swap
    program = PostfixParseString("swap")
    assert_equal([:swap], program)
  end

  def test_pop
    program = PostfixParseString("pop")
    assert_equal([:pop], program)
  end

  def test_booleans
    program = PostfixParseString("true")
    assert_equal([true], program)

    program = PostfixParseString("false")
    assert_equal([false], program)
  end

  def test_reference
    program = PostfixParseString("reference")
    assert_equal([:reference], program)
  end

  def test_assign_to_reference
    program = PostfixParseString("assign_to_reference")
    assert_equal([:assign_to_reference], program)
  end

  def test_reference_value
    program = PostfixParseString("reference_value")
    assert_equal([:reference_value], program)
  end

  def test_delete_reference
    program = PostfixParseString("delete_reference")
    assert_equal([:delete_reference], program)
  end

  def test_stacktop
    program = PostfixParseString("stacktop")
    assert_equal([:stacktop], program)
  end

  def test_and
    program = PostfixParseString("and")
    assert_equal([:and], program)
  end

  def test_or
    program = PostfixParseString("or")
    assert_equal([:or], program)
  end

  def test_not
    program = PostfixParseString("not")
    assert_equal([:not], program)
  end

  def PostfixParseFile
    program = PostfixParseFile("test_postfixsource.pf")
    assert_equal([7, 4, 3, :less, :if, 1, 3, 2, :swap, :exit], program)
  end

  #~ def comments
    #~ program = PostfixParseString("1(comment 1) 3 swap(comment 2, comment 3) exit (comment4)")
    #~ assert_equal([1, 3, :swap, :exit], program)

    #~ program = PostfixParseStringDebug("1(comment 1) 3 swap(comment 2, comment 3) exit (comment4)")
    #~ assert_equal([[1, "comment 0"], [3, nil], [:swap, "comment 2, comment 3"], [:exit, "comment4"]], program)
  #~ end
end

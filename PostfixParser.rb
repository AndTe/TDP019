require 'rdparse.rb'

class PostfixParser

  def initialize
    @p = []
    @PostParser = Parser.new("postfix parser") do
      token(/".*?[^\\]"/) {|m| m}
      token(/\s+/)
      token(/\d+/) {|m| m.to_i }
      token(/\+|-|\/|\*|duplicate|pop|goto|=|<|==|swap|exit|print|not|and|or/) {|m| m.to_sym }
      token(/./) {|m| m }
      
      start :expr do 
        match(:atom, :expr) { |a, b| a + b}
        match(:atom) { |a| a}
        #match(:expr, '+', :term) {|a, _, b| a + b }
        #match(:expr, '-', :term) {|a, _, b| a - b }
        #match(:term)
      end
      
      rule :atom do
        # Match the result of evaluating an integer expression, which
        # should be an Integer
        match(Integer) { |a| [a]}
        match(String){ |a| [a]}
        match(Symbol){ |a| [a]}
      end
      end
  end

  def generateshit(str)
    @PostParser.parse str
  end
  
  def log(state = true)
    if state
      @diceParser.logger.level = Logger::DEBUG
    else
      @diceParser.logger.level = Logger::WARN
    end
  end
end

p = "1 5 + 2 / exit"
pp = PostfixParser.new
p pp.generateshit p

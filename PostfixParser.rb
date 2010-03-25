require 'rdparse.rb'

class PostfixParser

  def initialize
    @p = []
    @PostParser = Parser.new("postfix parser") do
      token(/\+/) {:plus}
      token(/-/) {:minus}
      token(/\*/) {:multiply}
      token(/\//) {:divide}
      token(/==/) {:equals}
      token(/=/) {:assign}
      token(/</) {:less}
      token(/true/) {|m| true}
      token(/false/) {|m| false}
      token(/".*?[^\\]"/) {|m| m}
      token(/\s+/)
      token(/\d+/) {|m| m.to_i }
      token(/duplicate|pop|goto|swap|exit|print|not|and|or|if/) {|m| m.to_sym }
      
      #token(/./) {|m| m }
      
      start :expr do 
        match(:atom, :expr) { |a, b| a + b}
        match(:atom) { |a| a}
      end
      
      rule :atom do
        # Match the result of evaluating an integer expression, which
        # should be an Integer
        match(Integer) { |a| [a]}
        match(String){ |a| [a]}
        match(Symbol){ |a| [a]}
	match(FalseClass) {|a| [a]}
	match(TrueClass) {|a| [a]}
      end
      end
  end

  def parse_string(str)
    @PostParser.parse str
  end
  
  #~ def log(state = false)
    #~ if state
      #~ @diceParser.logger.level = Logger::DEBUG
    #~ else
      #~ @diceParser.logger.level = Logger::WARN
    #~ end
  #~ end
end

def PostfixParseString(postfix)
  p = PostfixParser.new
  temp = p.parse_string postfix
  #p temp
  temp
end

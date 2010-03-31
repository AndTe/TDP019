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
      token(/true/) {:true}
      token(/false/) {:false}
      token(/nil/) {nil}
      token(/".*?[^\\]"/) {|m| m}
      token(/\s+/)
      token(/\d+/) {|m| m.to_i }
      token(/duplicate|pop|goto|swap|exit|print|not|and|or|if|assign_to_reference|reference_value|delete_reference|reference/) {|m| m.to_sym }

      start :expr do
        match(:atom, :expr) { |a, b| a + b}
        match(:atom) { |a| a}
      end

      rule :atom do
        match(Integer) { |a| [a]}
        match(String){ |a| [a]}
        match(Symbol){ |a| [a]}
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
  p.parse_string postfix
end

def PostfixParseFile(sourcefile)
  source = open(sourcefile)
  p = PostfixParser.new
  p.parse_string source.read
end

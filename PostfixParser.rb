require 'rdparse.rb'

class PostfixParser
  def initialize
    @PostParser = Parser.new("postfix parser") do
      token(/\+/) {:plus}
      token(/-/) {:minus}
      token(/\*/) {:multiply}
      token(/\//) {:divide}
      token(/==/) {:equals}
      token(/</) {:less}
      token(/".*?[^\\]"/) {|m| m}
      token(/\s+/)
      token(/\d+/) {|m| m.to_i }
      token(/stacktop|pop|goto|swap|exit|print|not|and|or|if|assign_to_reference|reference_value|delete_reference|reference|true|false/) {|m| m.to_sym}

      start :expr do
        match(:atom, :expr) {|a, b| [a] + b}
        match(:atom) {|a| [a]}
      end

      rule :atom do
        match(:true) {true}
        match(:false) {false}
        match(Integer) {|a| a}
        match(String) {|a| a}
        match(Symbol) {|a| a}
      end
    end
  end

  def parse_string(str)
    @PostParser.parse str
  end
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

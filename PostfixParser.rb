class PostfixParser
  def initialize
   @keywords = {
      "+" => :plus,
      "-" => :minus,
      "*" => :multiply,
      "/" => :divide,
      "==" => :equals,
      "<" => :less,
      "not" => :not,
      "and" => :and,
      "or" => :or,
      "goto" => :goto,
      "if" => :if,
      "exit" => :exit,
      "stacktop" => :stacktop,
      "pop" => :pop,
      "assign_to_reference" => :assign_to_reference,
      "reference_value" => :reference_value,
      "delete_reference" => :delete_reference,
      "reference" => :reference,
      "output" => :output,
      "input" => :input,
      "swap" => :swap,
      "true" => true,
      "false" => false}
  end

  def parse_string(str)
    tokens = str.split(/\s+/)

    # get Postfix instructions
    pi = tokens.map{|token|
      if @keywords[token] != nil
        @keywords[token]
      elsif token.match(/^\d+$/)
        token.to_i
      else
        raise "Not a Postfix command: \"#{token}\""
      end
    }
    pi
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

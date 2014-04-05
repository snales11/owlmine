class OntologyStatement < ActiveRecord::Base
  unloadable
  has_many :ontology_raw_changes, :dependent => :restrict
  has_many :ontology_changes, :through => :ontology_raw_changes 
  validates_presence_of :text
 
  def indented_text
    indent_size = 4
    space = ' '
    br = "\n"
    s = ''
    indent = 0
    quote = false
    
    for c in text.chars
      case c
      when '('
        indent += indent_size
        s << ':'
        s << br << space * indent
      when ')'
        indent -= indent_size
        s << br << space * indent
      when ' '
        if quote
          s << c
        else
          s << br << space * indent
        end
      when '"'
        quote = !quote
      else
        s << c
      end
    end
    s.strip
  end
end

module OwlmineHelper
  def action_string(action)
    case action
    when '+'
      'Added'
    when '-'
      'Removed'
    when '*'
      'Modified'
    else
      '???'
    end
  end
  
  def action_css_class(action)
    case action
    when '+'
      'diff_in'
    when '-'
      'diff_out'
    when '*'
      'diff_mod'
    else
      'diff_unk'
    end
  end
end

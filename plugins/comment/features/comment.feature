Feature: Comment

Scenario: Comment an unselected line
  When I open a new edit tab
  And I replace the contents with
    """
    foo
    bar
    """
  And I move the cursor to 0
  And I toggle block comment
  Then I should see in the edit tab
    """
    # foo
    bar
    """

Scenario: Comment a selected line
  When I open a new edit tab
  And I replace the contents with
    """
    foo
    bar
    """
  And I select from 0 to 3
  And I toggle block comment
  Then I should see in the edit tab
    """
    # foo
    bar
    """

Scenario: Comment a partially selected line (start)
  When I open a new edit tab
  And I replace the contents with
    """
    foo
    bar
    """
  And I select from 0 to 1
  And I toggle block comment
  Then I should see in the edit tab
    """
    # foo
    bar
    """

Scenario: Comment a partially selected line (middle)
  When I open a new edit tab
  And I replace the contents with
    """
    foo
    bar
    """
  And I select from 1 to 2
  And I toggle block comment
  Then I should see in the edit tab
    """
    # foo
    bar
    """

Scenario: Comment a partially selected line (end)
  When I open a new edit tab
  And I replace the contents with
    """
    foo
    bar
    """
  And I select from 2 to 3
  And I toggle block comment
  Then I should see in the edit tab
    """
    # foo
    bar
    """

Scenario: Comment an unselected indented line
  When I open a new edit tab
  And I replace the contents with
    """
    def foo
      bar
    end
    """
  And I move the cursor to 8
  And I toggle block comment
  Then I should see in the edit tab
    """
    def foo
      # bar
    end
    """  

Scenario: Comment multiple selected lines
  When I open a new edit tab
  And I replace the contents with
    """
    foo
    bar
    baz
    """
  And I select from 0 to 7
  And I toggle block comment
  Then I should see in the edit tab
    """
    # foo
    # bar
    baz
    """

Scenario: Comment multiple selected lines, ignoring the line with with the selection at the start
  When I open a new edit tab
  And I replace the contents with
    """
    foo
    bar
    baz
    """
  And I select from 0 to 8
  And I toggle block comment
  Then I should see in the edit tab
    """
    # foo
    # bar
    baz
    """

Scenario: Comment an indented selection
  When I open a new edit tab
  And I replace the contents with
    """
    class Demo
      def foo
        "hi"
      end
    end
    """
  And I select from 11 to 35
  And I toggle block comment
  Then I should see in the edit tab
    """
    class Demo
      # def foo
      #   "hi"
      # end
    end
    """

Scenario: Comment multiple lines which include commented lines
  When I open a new edit tab
  And I replace the contents with
    """
    class Demo
      # def foo
      #   "hi"
      # end
    end
    """
  And I select from 0 to 45
  And I toggle block comment
  Then I should see in the edit tab
    """
    # class Demo
    #   # def foo
    #   #   "hi"
    #   # end
    # end
    """

Scenario: It preserves my selection
Scenario: It preserves my cursor position
Scenario: It makes edit as a single undo-item
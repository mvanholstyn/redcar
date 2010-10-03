Feature: Uncomment

Scenario: Uncomment an unselected line
  When I open a new edit tab
  And I replace the contents with
    """
    # foo
    bar
    """
  And I move the cursor to 0
  And I toggle block comment
  Then I should see in the edit tab
    """
    foo
    bar
    """

Scenario: Uncomment a selected line
  When I open a new edit tab
  And I replace the contents with
    """
    # foo
    bar
    """
  And I select from 0 to 5
  And I toggle block comment
  Then I should see in the edit tab
    """
    foo
    bar
    """

Scenario: Uncomment a partially selected line (start)
  When I open a new edit tab
  And I replace the contents with
    """
    # foo
    bar
    """
  And I select from 0 to 1
  And I toggle block comment
  Then I should see in the edit tab
    """
    foo
    bar
    """

Scenario: Uncomment a partially selected line (middle)
  When I open a new edit tab
  And I replace the contents with
    """
    # foo
    bar
    """
  And I select from 2 to 3
  And I toggle block comment
  Then I should see in the edit tab
    """
    foo
    bar
    """

Scenario: Uncomment a partially selected line (end)
  When I open a new edit tab
  And I replace the contents with
    """
    # foo
    bar
    """
  And I select from 4 to 5
  And I toggle block comment
  Then I should see in the edit tab
    """
    foo
    bar
    """

Scenario: Uncomment an unselected indented line
  When I open a new edit tab
  And I replace the contents with
    """
    def foo
      # bar
    end
    """
  And I move the cursor to 8
  And I toggle block comment
  Then I should see in the edit tab
    """
    def foo
      bar
    end
    """  

Scenario: Uncomment multiple selected lines
  When I open a new edit tab
  And I replace the contents with
    """
    # foo
    # bar
    baz
    """
  And I select from 0 to 11
  And I toggle block comment
  Then I should see in the edit tab
    """
    foo
    bar
    baz
    """

Scenario: Uncomment multiple selected lines, ignoring the line with with the selection at the start
  When I open a new edit tab
  And I replace the contents with
    """
    # foo
    # bar
    baz
    """
  And I select from 0 to 12
  And I toggle block comment
  Then I should see in the edit tab
    """
    foo
    bar
    baz
    """

Scenario: Uncomment an indented selection
  When I open a new edit tab
  And I replace the contents with
    """
    class Demo
      # def foo
      #   "hi"
      # end
    end
    """
  And I select from 11 to 41
  And I toggle block comment
  Then I should see in the edit tab
    """
    class Demo
      def foo
        "hi"
      end
    end
    """

Scenario: Uncomment multiple lines which include commented lines
  When I open a new edit tab
  And I replace the contents with
    """
    # class Demo
    #   # def foo
    #   #   "hi"
    #   # end
    # end
    """
  And I select from 0 to 55
  And I toggle block comment
  Then I should see in the edit tab
    """
    class Demo
      # def foo
      #   "hi"
      # end
    end
    """

Scenario: It properly uncomments lines without a space after the comment character
  When I open a new edit tab
  And I replace the contents with
    """
    #class Demo
    #  # def foo
    #  #   "hi"
    #  # end
    #end
    """
  And I select from 0 to 50
  And I toggle block comment
  Then I should see in the edit tab
    """
    class Demo
     # def foo
     #   "hi"
     # end
    end
    """

Scenario: It preserves my selection
Scenario: It preserves my cursor position
Scenario: It makes edit as a single undo-item
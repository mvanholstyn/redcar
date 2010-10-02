module Redcar
  class TextUtils
    def self.menus
      Menu::Builder.build do
        sub_menu "Edit" do
          item "Toggle Block Comment", ToggleBlockCommentCommand
        end
      end
    end

    def self.keymaps
      osx = Redcar::Keymap.build("main", :osx) do
        link "Cmd+/", ToggleBlockCommentCommand
      end
      linwin = Redcar::Keymap.build("main", [:linux, :windows]) do
        link "Ctrl+/", ToggleBlockCommentCommand
      end
      [osx, linwin]
    end

    class CursorHandler
      ##
      # Read cursor position and adjust line offset
      def initialize(doc)
        @doc = doc
        @cursor_line = @doc.cursor_line
        @top_line = @doc.smallest_visible_line
        @line_offset = @doc.cursor_line_offset
        line = @doc.get_line(@cursor_line)
      end

      ##
      # Adjust cursor offset and make visible
      def adjust
        @doc.cursor_offset = cursor_offset
      end
      
      def cursor_offset
        @doc.offset_at_line(@cursor_line) + @line_offset
      end
    end

    # Toggle block command.
    class ToggleBlockCommentCommand < DocumentCommand
      # The execution reuses the same dialog.
	    def execute
        # TODO: Needs to implement better bundle handling so that we can look up the comment characters from the bundles instead of having them hard-coded.
        comment = case Redcar::app.focussed_notebook_tab.edit_view.grammar
          when "Ruby" then "#"
          when "Ruby on Rails" then "#"
          when "Java" then "//"
          else "--"
        end

        cursor = CursorHandler.new(doc)
        doc.compound do
          # TODO: Prevent tidy from running?
          doc.edit_view.delay_parsing do
            if doc.selection?
              first_line_ix = doc.line_at_offset(doc.selection_range.begin)
              last_line_ix  = doc.line_at_offset(doc.selection_range.end)
              if doc.selection_range.end == doc.offset_at_line(last_line_ix)
                last_line_ix -= 1
              end

              lines = []
              first_line_ix.upto(last_line_ix) do |line_ix|
                lines << doc.get_line(line_ix)
              end
              
              column = lines.map { |line| line.index(/[^\s]/) || 0 }.min
              uncomment = lines.all? { |line| line =~ /^\s*#{Regexp.escape(comment)}/ }

              cursor_at_start = cursor.cursor_offset == doc.selection_range.begin
              start_selection = doc.selection_range.begin
              end_selection =  doc.selection_range.end

              first_line_ix.upto(last_line_ix) do |line_ix|
                if uncomment
                  uncomment_line(doc, line_ix, comment)
                else
                  chars_added = comment_line(doc, line_ix, comment, column)
                  if doc.offset_at_line(line_ix) + column < start_selection
                    start_selection += chars_added
                  end
                  end_selection += chars_added
                end
              end

              # TODO: keep selection & cursor for uncomment
              doc.set_selection_range(cursor_at_start ? start_selection : end_selection, cursor_at_start ? end_selection : start_selection)
            else
              line_ix = doc.cursor_line
              column = doc.get_line(line_ix).index(/[^\s]/) || 0
              uncomment = doc.get_line(line_ix) =~ /^\s*#{Regexp.escape(comment)}/
              if uncomment
                uncomment_line(doc, line_ix, comment)
              else
                chars_added = comment_line(doc, line_ix, comment, column)
                doc.cursor_offset = cursor.cursor_offset + chars_added
              end
            end
          end
        end
      end

      def comment_line(doc, line_ix, comment, column)
        text = doc.get_line(line_ix)
        comment_text = "#{comment} "
        unless text =~ /^\s*#{Regexp.escape(comment)}/
          doc.insert(doc.offset_at_line(line_ix) + column, comment_text)
          comment_text.size
        else
          0
        end
      end

      def uncomment_line(doc, line_ix, comment)
        text = doc.get_line(line_ix).chomp
        text = text.sub(/^(\s*)#{Regexp.escape(comment)}\s*/, '\1')
        doc.replace_line(line_ix, text)
      end
    end
  end
end

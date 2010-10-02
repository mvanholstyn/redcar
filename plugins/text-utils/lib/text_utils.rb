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
      def initialize(doc)
        @doc = doc
        @cursor_line = @doc.cursor_line
        @top_line = @doc.smallest_visible_line
        @line_offset = @doc.cursor_line_offset
        line = @doc.get_line(@cursor_line)
      end

      def cursor_offset
        @doc.offset_at_line(@cursor_line) + @line_offset
      end
    end

    class ToggleBlockCommentCommand < DocumentCommand
	    def execute
        comment_character = lookup_comment_character(doc)

        return unless comment_character

        cursor = CursorHandler.new(doc)
        doc.compound do
          # TODO: Prevent tidy from running?
          # TODO: What is this edit_view.delay_parsing?
          doc.edit_view.delay_parsing do
            if multi_line_selection?(doc)
              first_line_ix, last_line_ix = first_and_last_line_for_selection(doc)

              lines = []
              first_line_ix.upto(last_line_ix) do |line_ix|
                lines << doc.get_line(line_ix)
              end

              column = lines.map { |line| line.index(/[^\s]/) || 0 }.min
              uncomment = lines.all? { |line| line =~ /^\s*#{Regexp.escape(comment_character)}/ }

              cursor_at_start = cursor.cursor_offset == doc.selection_range.begin
              start_selection = doc.selection_range.begin
              end_selection =  doc.selection_range.end

              first_line_ix.upto(last_line_ix) do |line_ix|
                if uncomment
                  chars_removed_index, chars_removed = uncomment_line(doc, line_ix, comment_character)

                  if chars_removed > 0 and start_selection > chars_removed_index
                    start_selection -= chars_removed
                  end
                  end_selection -= chars_removed
                else
                  chars_added_index, chars_added = comment_line(doc, line_ix, comment_character, column)

                  if chars_added > 0 and start_selection > chars_added_index
                    start_selection += chars_added
                  end
                  end_selection += chars_added
                end
              end

              doc.set_selection_range(cursor_at_start ? start_selection : end_selection, cursor_at_start ? end_selection : start_selection)

            # TODO: Support commenting just the selection? via /* */ or # to the end of the line
            # TODO: preserve selection when a single line (part or whole) is selected
            # TODO: handle scenario when selection from end of one line to start of next line
            else
              column = doc.get_line(doc.cursor_line).index(/[^\s]/) || 0
              uncomment = doc.get_line(doc.cursor_line) =~ /^\s*#{Regexp.escape(comment_character)}/
              if uncomment
                chars_removed_index, chars_removed = uncomment_line(doc, doc.cursor_line, comment_character)

                if chars_removed > 0 and cursor.cursor_offset >= chars_removed_index
                  doc.cursor_offset = cursor.cursor_offset - chars_removed
                end
              else
                chars_added_index, chars_added = comment_line(doc, doc.cursor_line, comment_character, column)

                if chars_added > 0 and cursor.cursor_offset >= chars_added_index
                  doc.cursor_offset = cursor.cursor_offset + chars_added
                end
              end
            end
          end
        end
      end

      # TODO: Needs to implement better bundle handling so that we can look up the comment characters from the bundles instead of having them hard-coded.
      def lookup_comment_character(doc)
        case doc.edit_view.grammar
          when "Ruby" then "#"
          when "Ruby on Rails" then "#"
          when "Java" then "//"
        end
      end

      def single_line_selection?(doc)
        first_line, last_line = first_and_last_line_for_selection(doc)
        doc.selection? and first_line == last_line
      end

      def multi_line_selection?(doc)
        doc.selection? and not single_line_selection?(doc)
      end

      def first_and_last_line_for_selection(doc)
        first_line = doc.line_at_offset(doc.selection_range.begin)
        last_line = doc.line_at_offset(doc.selection_range.end)

        if doc.selection_range.end == doc.offset_at_line(last_line)
          last_line -= 1
        end

        [first_line, last_line]
      end

      def comment_line(doc, line_ix, comment_character, column)
        text = doc.get_line(line_ix)
        comment_text = "#{comment_character} "
        doc.insert(doc.offset_at_line(line_ix) + column, comment_text)
        [doc.offset_at_line(line_ix) + column, comment_text.size]
      end

      def uncomment_line(doc, line_ix, comment_character)
        text = doc.get_line(line_ix)
        if text =~ /^(\s*)(#{Regexp.escape(comment_character)}\s?)/
          doc.delete(doc.offset_at_line(line_ix) + $1.length, $2.length)
          [doc.offset_at_line(line_ix) + $1.length, $2.length]
        else
          [0, 0]
        end
      end
    end
  end
end

module Redcar
  class Comment
    def self.menus
      Menu::Builder.build do
        sub_menu "Edit" do
          item "Toggle Comment", ToggleCommentCommand
        end
      end
    end

    def self.keymaps
      osx = Redcar::Keymap.build("main", :osx) do
        link "Cmd+/", ToggleCommentCommand
      end
      linwin = Redcar::Keymap.build("main", [:linux, :windows]) do
        link "Ctrl+/", ToggleCommentCommand
      end
      [osx, linwin]
    end

    class ToggleCommentCommand < DocumentCommand
	    def execute
        comment_character = lookup_comment_character(doc)

        return unless comment_character

        doc.compound do
          # TODO: Prevent tidy from running?
          # TODO: What is this edit_view.delay_parsing?
          doc.edit_view.delay_parsing do
            doc.preserve_selection_and_cursor do
              if multi_line_selection?(doc)
                first_line_ix, last_line_ix = first_and_last_line_for_selection(doc)

                lines = []
                first_line_ix.upto(last_line_ix) do |line_ix|
                  lines << doc.get_line(line_ix)
                end

                column = lines.map { |line| line.index(/[^\s]/) || 0 }.min
                uncomment = lines.all? { |line| line =~ /^\s*#{Regexp.escape(comment_character)}/ }

                first_line_ix.upto(last_line_ix) do |line_ix|
                  if uncomment
                    chars_removed_index, chars_removed = uncomment_line(doc, line_ix, comment_character)
                  else
                    chars_added_index, chars_added = comment_line(doc, line_ix, comment_character, column)
                  end
                end

                # TODO: Support commenting just the selection? via /* */ or # to the end of the line
                # TODO: handle scenario when selection from end of one line to start of next line
              else
                column = doc.get_line(doc.cursor_line).index(/[^\s]/) || 0
                uncomment = doc.get_line(doc.cursor_line) =~ /^\s*#{Regexp.escape(comment_character)}/
                if uncomment
                  uncomment_line(doc, doc.cursor_line, comment_character)
                else
                  comment_line(doc, doc.cursor_line, comment_character, column)
                end
              end
            end
          end
        end
      end

      # TODO: Needs to implement better bundle handling so that we can look up
      # the comment characters from the bundles instead of having them hard-coded.
      def lookup_comment_character(doc)
        "#"
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
        comment_text = "#{comment_character} "
        doc.insert(doc.offset_at_line(line_ix) + column, comment_text)
      end

      def uncomment_line(doc, line_ix, comment_character)
        if doc.get_line(line_ix) =~ /^(\s*)(#{Regexp.escape(comment_character)}\s?)/
          doc.delete(doc.offset_at_line(line_ix) + $1.length, $2.length)
        end
      end
    end
  end
end

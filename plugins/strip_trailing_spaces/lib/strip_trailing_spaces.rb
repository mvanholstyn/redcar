
module Redcar
  class StripTrailingSpaces
    def self.enabled?
      Redcar::StripTrailingSpaces.storage['enabled']
    end

    def self.enabled=(bool)
      Redcar::StripTrailingSpaces.storage['enabled'] = bool
    end

    def self.strip_blank_lines?
      Redcar::StripTrailingSpaces.storage['strip_blank_lines']
    end

    def self.strip_blank_lines=(bool)
      Redcar::StripTrailingSpaces.storage['strip_blank_lines'] = bool
    end

    def self.storage
      @storage ||= begin
        storage = Plugin::Storage.new('strip_trailing_spaces_plugin')
        storage.set_default('enabled', false)
        storage.set_default('strip_blank_lines', false)
        storage
      end
    end

    def self.menus
      Menu::Builder.build do
        sub_menu "Plugins" do
          sub_menu "Strip Trailing Spaces", :priority => 195 do
            item "Enabled", :command => ToggleStripTrailingSpaces, :type => :check, :active => StripTrailingSpaces.enabled?
            item "Strip Blank Lines", :command => ToggleStripBlankLines, :type => :check, :active => StripTrailingSpaces.strip_blank_lines?
          end
        end
      end
    end

    def self.before_save(doc)
      if (doc.mirror.is_a?(Redcar::Project::FileMirror) && StripTrailingSpaces.enabled?)
        cursor = CursorHandler.new(doc)

        doc.controllers(Redcar::AutoPairer::DocumentController).first.ignore do
          doc.controllers(Redcar::AutoIndenter::DocumentController).first.ignore do
            doc.compound do
              doc.line_count.times do |l|
                doc.replace_line(l) do |line_text|
                  stripped = line_text.rstrip
                  (stripped.length > 0 || StripTrailingSpaces.strip_blank_lines?) ? stripped : line_text
                end
              end
            end
          end
        end

        cursor.adjust
      end
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
        @line_offset = line.rstrip.size if @line_offset > line.rstrip.size
      end

      ##
      # Adjust cursor offset and make visible
      def adjust
        offset=@doc.offset_at_line(@cursor_line) + @line_offset
        @doc.cursor_offset=offset
      end
    end

    class ToggleStripTrailingSpaces < Redcar::Command
      def execute
        StripTrailingSpaces.enabled = !StripTrailingSpaces.enabled?
      end
    end

    class ToggleStripBlankLines < Redcar::Command
      def execute
        StripTrailingSpaces.strip_blank_lines = !StripTrailingSpaces.strip_blank_lines?
      end
    end
  end
end

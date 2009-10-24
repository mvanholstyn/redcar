module Redcar
  class ApplicationSWT
    class Notebook
      attr_reader :tab_folder
      
      def initialize(model, tab_folder)
        @model, @tab_folder = model, tab_folder
        @model.controller = self
        attach_listeners
      end
      
      def attach_listeners
        @model.add_listener(:tab_added) do |tab|
          tab.controller = Redcar.gui.controller_for(tab).new(tab, self)
        end
      end
      
      def focussed_tab
        focussed_tab_item = tab_folder.get_selection
        @model.tabs.detect {|tab| tab.controller.item == focussed_tab_item}
      end
    end
  end
end
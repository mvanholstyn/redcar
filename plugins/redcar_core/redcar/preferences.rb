
module Redcar
  def self.preferences(name)
    $BUS['/redcar/preferences/'+name].data
  end
    
  def self.set_preference(name, value)
    $BUS['/redcar/preferences/'+name].data = value
    $BUS['/redcar/preferences/'].manager.save
  end
  
  PrefLogger = Logger.new("prefs.log")
  module PreferencesBuilder
    FreeBASE::Properties.new("Redcar Preferences", 
                             Redcar::VERSION, 
                             $BUS['/redcar/preferences'], 
                             File.dirname(__FILE__) + "/../../../custom/preferences.yaml")
    
#     module ClassMethods
      def preference(name)
        PrefLogger.info("PreferencesBuilder.preferences(#{name}):in")
        preferences_slot = $BUS['/redcar/preferences']
        builder = Builder.new
        yield builder
        preferences_slot[name].attr_pref = true
        if preferences_slot[name].data.nil?
          preferences_slot[name].data = builder.default
        end
        preferences_slot[name].attr_default = builder.default
        preferences_slot[name].attr_type = builder.type
        preferences_slot[name].attr_widget = builder.widget
        preferences_slot[name].attr_values = builder.values
        preferences_slot[name].attr_change = builder.change_proc
        preferences_slot[name].attr_bounds = builder.bounds
        preferences_slot[name].attr_step = builder.step
        PrefLogger.info("PreferencesBuilder.preferences(#{name}):out")
      end
      
      class Builder
        attr_accessor(:default, :widget, :values, :change_proc, :type,
                      :bounds, :step)
        
        def change(&block)
          @change_proc = block
        end
      end
#     end
    
#     def self.included(klass)
#       klass.extend ClassMethods
#     end
  end
  
  class PreferencesDialog < Gtk::Dialog
    def build_dialog
      self.set_size_request(600, 500)
      vb = self.vbox
      hb = Gtk::HBox.new
      vb.pack_start(hb)
      fr1 = Gtk::Frame.new("Group")
      fr1.set_size_request(150, 0)
      @frame = Gtk::Frame.new("Options")
      vs = Gtk::VSeparator.new
      hb.pack_start(fr1)
      hb.pack_start(vs, false, true)
      hb.pack_start(@frame)
      @sw = Gtk::ScrolledWindow.new
      @sw.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)
      fr1.add(@sw)
      vb.show_all
    end
    
    def initialize
      PrefLogger.info("PreferencesDialog#initialize():in")
      super("Preferences", Redcar.current_window, Gtk::Dialog::DESTROY_WITH_PARENT,
            [Gtk::Stock::OK,  Gtk::Dialog::RESPONSE_OK],
            [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL])
      build_dialog
      @dialog = self
      @preferences_slot = $BUS['/redcar/preferences/']
      @properties = @preferences_slot.manager

      @ts = Gtk::TreeStore.new(String, String)
      @tv = Gtk::TreeView.new(@ts)
      renderer = Gtk::CellRendererText.new
      col = Gtk::TreeViewColumn.new("", renderer, :text => 0)
      @tv.append_column(col)
      @tv.headers_visible = false
      populate_list(@preferences_slot, nil)
      @tv.show
      
      @sw.add(@tv)
      
      @initial_values = {}
      @on_change = {}
      
      @tv.signal_connect('cursor-changed') do |iter|
        build_widgets(@tv.selection.selected)
      end
      
      @dialog.signal_connect("response") do |_, resp_id|
        case resp_id
        when Gtk::Dialog::RESPONSE_CANCEL
          on_cancel
        when Gtk::Dialog::RESPONSE_OK
          on_ok
        end
      end
      
      @lazy_apply = []
      
      @properties.save
      PrefLogger.info("PreferencesDialog#initialize():out")
    end
    
    def populate_list(parent_slot, parent_iter)
      PrefLogger.info("PreferencesDialog#populate_list(#{parent_slot}, #{parent_iter}):in")
      parent_slot.each_slot do |slot|
        unless slot.attr_pref
          iter = @ts.append(parent_iter)
          @ts.set_value(iter, 0, slot.name)
          @ts.set_value(iter, 1, slot.path)
          populate_list(slot, iter)
        end
      end
      PrefLogger.info("PreferencesDialog#populate_list(#{parent_slot}, #{parent_iter}):out")
    end
    
     def on_ok
      PrefLogger.info("PreferencesDialog#on_ok():in")
      if @current_path
        save_values
      end
      @lazy_apply.each {|p| p.call}
      @dialog.destroy
      PrefLogger.info("PreferencesDialog#on_ok():out")
     end
    
    def on_cancel
      PrefLogger.info("PreferencesDialog#on_cancel():in")
      @dialog.destroy
      PrefLogger.info("PreferencesDialog#on_cancel():out")
    end
    
    def save_values
      PrefLogger.info("PreferencesDialog#save_values():in")
      @widgets.each do |pref_path, widget|
        val = widget.preference_value
        @lazy_apply << fn { 
          $BUS[pref_path].data = val  
          if @initial_values[pref_path] and 
              @initial_values[pref_path] != val and
              @on_change[pref_path] != nil
            PrefLogger.info("Applying prefererence:#{pref_path}, value:#{val}")
            @on_change[pref_path].call
            PrefLogger.info("Done prefererence:#{pref_path}, value:#{val}")
          end
        }
      end
      PrefLogger.info("PreferencesDialog#save_values():out")
    end
    
    def build_widgets(iter)
      PrefLogger.info("PreferencesDialog#build_widgets(#{iter}):in")
      if @current_path
        save_values
      end
      path = iter[1]
      @current_path = path
      vbox = Gtk::VBox.new
      @widgets = {}
      $BUS[path].each_slot do |slot|
        if slot.attr_pref
          name = slot.name
          if widget = slot.attr_widget
            label = Gtk::Label.new(name)
            if widget.is_a? Proc
              widget = widget.call
            end
          else
            case slot.attr_type
            when :string
              label = Gtk::Label.new(name)
              widget = Gtk::Entry.new
              widget.text = slot.data
              def widget.preference_value
                self.text
              end
            when :integer
              label = Gtk::Label.new(name)
              if bounds = slot.attr_bounds
                widget = Gtk::SpinButton.new(bounds[0].to_f, 
                                             bounds[1].to_f,
                                             (slot.attr_step||1).to_f)
              else
                widget = Gtk::SpinButton.new
              end
              widget.value = slot.data
              def widget.preference_value
                self.value.to_s
              end
            when :combo
              label = Gtk::Label.new(name)
              widget = Gtk::ComboBox.new
              if slot.attr_values.is_a? Array
                values = slot.attr_values
              elsif slot.attr_values.is_a? Proc
                values = slot.attr_values.call
              end
              values.each do |entry|
                widget.append_text(entry)
              end
              unless current_value = values.index(slot.data)
                raise "No such value in combo box: #{name}"
              end
              widget.active = current_value
              def widget.preference_value
                self.active_text
              end
            when :toggle
              label = nil
              widget = Gtk::CheckButton.new(name)
              widget.active = slot.data.to_bool
              def widget.preference_value
                self.active?.to_s
              end
            end
          end
          hbox = Gtk::HBox.new
          hbox.pack_start(label) if label
          hbox.pack_start(widget)
          vbox.pack_start(hbox, false)
          hbox.show_all
          @widgets[slot.path] = widget
          @initial_values[slot.path] = widget.preference_value
          @on_change[slot.path] = slot.attr_change
        end
      end
      @frame.children.each {|child| @frame.remove(child)}
      @frame.add(vbox)
      vbox.show
      PrefLogger.info("PreferencesDialog#build_widgets(#{iter}):out")
    end
  end
end

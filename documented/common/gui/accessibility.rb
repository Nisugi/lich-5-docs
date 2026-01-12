
module Lich
  module Common
    module GUI
      module Accessibility
        # Initializes accessibility features for the GUI.
        # In GTK3, accessibility is enabled by default through ATK.
        # @note Accessibility is not available on any non-linux platform.
        # @example Initializing accessibility
        #   Lich::Common::GUI::Accessibility.initialize_accessibility
        def self.initialize_accessibility
          # In GTK3, accessibility is enabled by default through ATK
          # Ensure ATK is loaded by referencing a Gail widget type
          # accessibility is not available on any non-linux platform
          begin
            GLib::Object.type_from_name('GailWidget')
          rescue NoMethodError => e
            Lich.log "warning: Could not initialize accessibility: #{e.message}" if OS.linux?
          end
        end

        # Makes a widget accessible for assistive technologies.
        # @param widget [Object] The widget to make accessible.
        # @param label [String] The accessible name for the widget.
        # @param description [String, nil] The accessible description for the widget.
        # @param role [Symbol, nil] The role of the widget (e.g., :button, :text).
        # @return [void]
        # @example Making a widget accessible
        #   Accessibility.make_accessible(my_widget, "My Widget", "This is a widget", :button)
        def self.make_accessible(widget, label, description = nil, role = nil)
          return unless widget.respond_to?(:get_accessible)

          begin
            accessible = widget.get_accessible
            return unless accessible

            # Set accessible name
            accessible.set_name(label) if accessible.respond_to?(:set_name)

            # Set accessible description
            accessible.set_description(description) if description && accessible.respond_to?(:set_description)

            # Set accessible role
            if role && accessible.respond_to?(:set_role)
              role_value = get_atk_role(role)
              accessible.set_role(role_value) if role_value
            end
          rescue StandardError => e
            Lich.log "warning: Could not make widget accessible: #{e.message}"
          end
        end

        # Makes a button accessible for assistive technologies.
        # @param button [Gtk::Button] The button to make accessible.
        # @param label [String] The accessible name for the button.
        # @param description [String, nil] The accessible description for the button.
        # @return [void]
        # @example Making a button accessible
        #   Accessibility.make_button_accessible(my_button, "Submit", "Click to submit the form")
        def self.make_button_accessible(button, label, description = nil)
          make_accessible(button, label, description, :button)

          # Ensure button has a visible label for screen readers
          begin
            if button.child.is_a?(Gtk::Label)
              button.child.set_text(label) if button.child.text.empty?
            elsif !button.label.nil? && button.label.empty?
              button.label = label
            end
          rescue StandardError => e
            Lich.log "warning: Could not set button label: #{e.message}"
          end
        end

        # Makes an entry widget accessible for assistive technologies.
        # @param entry [Gtk::Entry] The entry widget to make accessible.
        # @param label [String] The accessible name for the entry.
        # @param description [String, nil] The accessible description for the entry.
        # @return [void]
        # @example Making an entry accessible
        #   Accessibility.make_entry_accessible(my_entry, "Username", "Enter your username")
        def self.make_entry_accessible(entry, label, description = nil)
          make_accessible(entry, label, description, :text)
        end

        # Makes a combo box accessible for assistive technologies.
        # @param combo [Gtk::ComboBox] The combo box to make accessible.
        # @param label [String] The accessible name for the combo box.
        # @param description [String, nil] The accessible description for the combo box.
        # @return [void]
        # @example Making a combo box accessible
        #   Accessibility.make_combo_accessible(my_combo, "Select an option", "Choose from the list")
        def self.make_combo_accessible(combo, label, description = nil)
          make_accessible(combo, label, description, :combo_box)
        end

        # Makes a tab in a notebook accessible for assistive technologies.
        # @param notebook [Gtk::Notebook] The notebook containing the tab.
        # @param page [Gtk::Widget] The page to make accessible.
        # @param tab_label [String] The accessible name for the tab.
        # @param description [String, nil] The accessible description for the tab.
        # @return [void]
        # @example Making a tab accessible
        #   Accessibility.make_tab_accessible(my_notebook, my_page, "Tab 1", "This is the first tab")
        def self.make_tab_accessible(notebook, page, tab_label, description = nil)
          begin
            page_num = notebook.page_num(page)
            return if page_num == -1

            tab = notebook.get_tab_label(page)
            make_accessible(tab, tab_label, description, :page_tab)

            # Also make the page itself accessible
            make_accessible(page, tab_label, description, :panel)
          rescue StandardError => e
            Lich.log "warning: Could not make tab accessible: #{e.message}"
          end
        end

        # Makes a window accessible for assistive technologies.
        # @param window [Gtk::Window] The window to make accessible.
        # @param title [String] The accessible name for the window.
        # @param description [String, nil] The accessible description for the window.
        # @return [void]
        # @example Making a window accessible
        #   Accessibility.make_window_accessible(my_window, "Main Window", "This is the main application window")
        def self.make_window_accessible(window, title, description = nil)
          make_accessible(window, title, description, :window)

          # Ensure window has a title for screen readers
          begin
            window.title = title if window.title.nil? || window.title.empty?
          rescue StandardError => e
            Lich.log "warning: Could not set window title: #{e.message}"
          end
        end

        # Adds keyboard navigation capabilities to a widget.
        # @param widget [Object] The widget to add keyboard navigation to.
        # @param can_focus [Boolean] Whether the widget can receive focus.
        # @param tab_order [Integer, nil] The tab order of the widget.
        # @return [void]
        # @example Adding keyboard navigation
        #   Accessibility.add_keyboard_navigation(my_widget, true, 1)
        def self.add_keyboard_navigation(widget, can_focus = true, tab_order = nil)
          begin
            widget.can_focus = can_focus

            # In GTK3, we need to check if the property exists before setting it
            if tab_order && widget.class.property?('tab-position')
              widget.set_property('tab-position', tab_order)
            end
          rescue StandardError => e
            Lich.log "warning: Could not set keyboard navigation: #{e.message}"
          end
        end

        # Adds a keyboard shortcut to a widget.
        # @param widget [Object] The widget to add the shortcut to.
        # @param key [String] The key for the shortcut.
        # @param modifiers [Array<Symbol>] The modifiers for the shortcut (e.g., [:control]).
        # @return [void]
        # @example Adding a keyboard shortcut
        #   Accessibility.add_keyboard_shortcut(my_widget, "F1", [:control])
        def self.add_keyboard_shortcut(widget, key, modifiers = [])
          return unless widget.respond_to?(:add_accelerator)

          begin
            # Convert modifiers to Gdk::ModifierType
            modifier_mask = 0
            modifiers.each do |mod|
              case mod
              when :control, :ctrl
                modifier_mask |= Gdk::ModifierType::CONTROL_MASK
              when :shift
                modifier_mask |= Gdk::ModifierType::SHIFT_MASK
              when :alt
                modifier_mask |= Gdk::ModifierType::MOD1_MASK
              end
            end

            # Find or create accelerator group
            if widget.parent.is_a?(Gtk::Window)
              # Get the first accel group (replacing the unreachable loop)
              accel_group = widget.parent.accel_groups.first

              # Create new accel group if none found
              if accel_group.nil?
                accel_group = Gtk::AccelGroup.new
                widget.parent.add_accel_group(accel_group)
              end

              # Add accelerator
              widget.add_accelerator(
                "activate",
                accel_group,
                Gdk::Keyval.from_name(key),
                modifier_mask,
                Gtk::AccelFlags::VISIBLE
              )
            end
          rescue StandardError => e
            Lich.log "warning: Could not add keyboard shortcut: #{e.message}"
          end
        end

        # Announces a message through a widget for assistive technologies.
        # @param widget [Object] The widget to announce the message through.
        # @param message [String] The message to announce.
        # @param _priority [Symbol] The priority of the announcement (default: :medium).
        # @return [void]
        # @example Announcing a message
        #   Accessibility.announce(my_widget, "New message received")
        def self.announce(widget, message, _priority = :medium)
          return unless widget.respond_to?(:get_accessible)

          begin
            accessible = widget.get_accessible
            return unless accessible

            # In GTK3/ATK, we can use state changes to trigger screen reader announcements
            if accessible.respond_to?(:notify_state_change)
              # Toggle state to trigger announcement
              accessible.notify_state_change(Atk::StateType::SHOWING, true)

              # Set name to message temporarily
              original_name = nil
              if accessible.respond_to?(:get_name) && accessible.respond_to?(:set_name)
                original_name = accessible.get_name
                accessible.set_name(message)
              end

              # Restore original name after a short delay
              if original_name
                # Using one-shot timeout (returns false to prevent repetition)
                GLib::Timeout.add(1000) do
                  accessible.set_name(original_name)
                  false # Intentionally return false to run only once
                end
              end
            end
          rescue StandardError => e
            Lich.log "warning: Could not announce message: #{e.message}"
          end
        end

        # Creates an accessible label for an input widget.
        # @param container [Gtk::Box, Gtk::Grid] The container to add the label and input to.
        # @param input [Gtk::Widget] The input widget to associate with the label.
        # @param text [String] The text for the label.
        # @param position [Symbol] The position of the label relative to the input (e.g., :left, :right).
        # @return [Gtk::Label] The created label.
        # @example Creating an accessible label
        #   label = Accessibility.create_accessible_label(my_box, my_entry, "Username", :left)
        def self.create_accessible_label(container, input, text, position = :left)
          label = Gtk::Label.new(text)
          label.set_alignment(position == :left ? 1 : 0, 0.5)

          # Connect label to input for screen readers
          if input.respond_to?(:get_accessible) && label.respond_to?(:get_accessible)
            input_accessible = input.get_accessible
            label_accessible = label.get_accessible

            if input_accessible && label_accessible &&
               input_accessible.respond_to?(:add_relationship) &&
               defined?(Atk::RelationType::LABEL_FOR)
              label_accessible.add_relationship(Atk::RelationType::LABEL_FOR, input_accessible)
            end
          end

          # Add to container based on position
          case container
          when Gtk::Box
            case position
            when :left
              container.pack_start(label, expand: false, fill: false, padding: 5)
              container.pack_start(input, expand: true, fill: true, padding: 5)
            when :right
              container.pack_start(input, expand: true, fill: true, padding: 5)
              container.pack_start(label, expand: false, fill: false, padding: 5)
            when :top, :bottom
              # For top/bottom, we need to change the box orientation or create a vertical box
              vbox = if container.orientation == :vertical
                       container
                     else
                       vbox = Gtk::Box.new(:vertical, 5)
                       container.add(vbox)
                       vbox
                     end

              if position == :top
                vbox.pack_start(label, expand: false, fill: false, padding: 2)
                vbox.pack_start(input, expand: true, fill: true, padding: 2)
              else
                vbox.pack_start(input, expand: true, fill: true, padding: 2)
                vbox.pack_start(label, expand: false, fill: false, padding: 2)
              end
            end
          when Gtk::Grid
            # For Grid, we need row and column information which isn't provided
            # This is a simplified version
            container.add(label)
            container.add(input)
          else
            # For other containers, just add both
            container.add(label)
            container.add(input)
          end

          label
        end

        # Retrieves the ATK role corresponding to a given symbol.
        # @param role_symbol [Symbol] The symbol representing the role (e.g., :button).
        # @return [Atk::Role, nil] The corresponding ATK role or nil if not found.
        # @example Getting an ATK role
        #   role = Accessibility.get_atk_role(:button)
        def self.get_atk_role(role_symbol)
          return nil unless defined?(Atk::Role)

          begin
            case role_symbol
            when :button then Atk::Role::PUSH_BUTTON
            when :text then Atk::Role::TEXT
            when :combo_box then Atk::Role::COMBO_BOX
            when :page_tab then Atk::Role::PAGE_TAB
            when :panel then Atk::Role::PANEL
            when :window then Atk::Role::FRAME
            when :label then Atk::Role::LABEL
            when :list then Atk::Role::LIST
            when :list_item then Atk::Role::LIST_ITEM
            when :menu then Atk::Role::MENU
            when :menu_item then Atk::Role::MENU_ITEM
            when :check_box then Atk::Role::CHECK_BOX
            when :radio_button then Atk::Role::RADIO_BUTTON
            when :dialog then Atk::Role::DIALOG
            when :separator then Atk::Role::SEPARATOR
            when :scroll_bar then Atk::Role::SCROLL_BAR
            when :slider then Atk::Role::SLIDER
            when :spin_button then Atk::Role::SPIN_BUTTON
            when :table then Atk::Role::TABLE
            when :tree then Atk::Role::TREE
            when :tree_item then Atk::Role::TREE_ITEM
            else nil
            end
          rescue StandardError => e
            Lich.log "warning: Could not get ATK role: #{e.message}"
            nil
          end
        end

        class << self
          private :get_atk_role
        end
      end
    end
  end
end

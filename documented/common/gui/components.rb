
module Lich
  module Common
    module GUI
      module Components
        # Creates a new button with an optional label and CSS provider.
        # @param label [String, nil] The label for the button.
        # @param css_provider [Gtk::CssProvider, nil] The CSS provider to style the button.
        # @return [Gtk::Button] The created button.
        # @example Creating a button
        #   button = Lich::Common::GUI::Components.create_button(label: "Click Me")
        def self.create_button(label: nil, css_provider: nil)
          button = label ? Gtk::Button.new(label: label) : Gtk::Button.new
          button.style_context.add_provider(css_provider, Gtk::StyleProvider::PRIORITY_USER) if css_provider
          button
        end

        # Creates a horizontal button box containing the specified buttons.
        # @param buttons [Array<Gtk::Button>] The buttons to include in the box.
        # @param expand [Boolean] Whether the buttons should expand to fill the box.
        # @param fill [Boolean] Whether the buttons should fill the space allocated to them.
        # @param padding [Integer] The padding between buttons.
        # @return [Gtk::Box] The created button box.
        # @example Creating a button box
        #   box = Lich::Common::GUI::Components.create_button_box([button1, button2])
        def self.create_button_box(buttons, expand: false, fill: false, padding: 5)
          box = Gtk::Box.new(:horizontal)

          buttons.each do |button|
            box.pack_end(button, expand: expand, fill: fill, padding: padding)
          end

          box
        end

        # Creates a labeled entry field with an optional password visibility.
        # @param label_text [String] The text for the label.
        # @param entry_width [Integer] The width of the entry field in characters.
        # @param password [Boolean] Whether the entry should be a password field.
        # @return [Hash] A hash containing the label, entry, and box.
        # @example Creating a labeled entry
        #   entry = Lich::Common::GUI::Components.create_labeled_entry("Username:", entry_width: 20)
        def self.create_labeled_entry(label_text, entry_width: 15, password: false)
          label = Gtk::Label.new(label_text)
          label.set_width_chars(entry_width)

          entry = Gtk::Entry.new
          entry.visibility = !password if password

          pane = Gtk::Paned.new(:horizontal)
          pane.add1(label)
          pane.add2(entry)

          { label: label, entry: entry, box: pane }
        end

        # Creates a notebook widget with the specified pages and settings.
        # @param pages [Array<Hash>] An array of pages, each containing a :label and :widget.
        # @param tab_position [Symbol] The position of the tabs (:top, :bottom, :left, :right).
        # @param show_border [Boolean] Whether to show a border around the notebook.
        # @param css_provider [Gtk::CssProvider, nil] The CSS provider to style the notebook.
        # @return [Gtk::Notebook] The created notebook.
        # @example Creating a notebook
        #   notebook = Lich::Common::GUI::Components.create_notebook([{ label: "Tab 1", widget: widget1 }, { label: "Tab 2", widget: widget2 }])
        def self.create_notebook(pages, tab_position: :top, show_border: true, css_provider: nil)
          notebook = Gtk::Notebook.new
          notebook.set_tab_pos(tab_position)
          notebook.show_border = show_border

          if css_provider
            notebook.style_context.add_provider(css_provider, Gtk::StyleProvider::PRIORITY_USER)
          end

          # Track tab indices to avoid hardcoding page numbers
          notebook.define_singleton_method(:tab_indices) do
            @tab_indices ||= {}
          end

          pages.each do |page|
            label = page[:label]
            index = notebook.append_page(page[:widget], Gtk::Label.new(label))
            notebook.tab_indices[label] = index
          end

          notebook
        end
      end
    end
  end
end


module Lich
  module Common
    module GUI
      module Components
        # Creates a new button with an optional label and CSS provider.
        #
        # @param label [String, nil] the text to display on the button
        # @param css_provider [Gtk::CssProvider, nil] the CSS provider to style the button
        # @return [Gtk::Button] the created button
        def self.create_button(label: nil, css_provider: nil)
          button = label ? Gtk::Button.new(label: label) : Gtk::Button.new
          button.style_context.add_provider(css_provider, Gtk::StyleProvider::PRIORITY_USER) if css_provider
          button
        end

        # Creates a horizontal button box containing the specified buttons.
        #
        # @param buttons [Array<Gtk::Button>] the buttons to include in the box
        # @param expand [Boolean] whether the buttons should expand to fill the box
        # @param fill [Boolean] whether the buttons should fill the available space
        # @param padding [Integer] the padding between buttons
        # @return [Gtk::Box] the created button box
        def self.create_button_box(buttons, expand: false, fill: false, padding: 5)
          box = Gtk::Box.new(:horizontal)

          buttons.each do |button|
            box.pack_end(button, expand: expand, fill: fill, padding: padding)
          end

          box
        end

        # Creates a labeled entry field with an optional password visibility toggle.
        #
        # @param label_text [String] the text to display as the label
        # @param entry_width [Integer] the width of the entry field in characters
        # @param password [Boolean] whether the entry should hide the text for password input
        # @return [Hash] a hash containing the label, entry, and box
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

        # Creates a notebook widget with the specified pages and options.
        #
        # @param pages [Array<Hash>] an array of pages, each containing a :label and :widget
        # @param tab_position [Symbol] the position of the tabs (:top, :bottom, :left, :right)
        # @param show_border [Boolean] whether to show a border around the notebook
        # @param css_provider [Gtk::CssProvider, nil] the CSS provider to style the notebook
        # @return [Gtk::Notebook] the created notebook
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


module Lich
  module Common
    module GUI
      # Represents the parameters required for user login.
      #
      # This class encapsulates the user login parameters and provides methods to access them.
      # @see UIConfig
      # @see CallbackParams
      class LoginParams
        attr_accessor :user_id, :password, :char_name, :game_code, :game_name,
                      :frontend, :custom_launch, :custom_launch_dir,
                      :is_favorite, :favorite_order, :favorite_added

        # @option params [String] :user_id User ID/account name
        def initialize(params = {})
          @user_id = params[:user_id]
          @password = params[:password]
          @char_name = params[:char_name]
          @game_code = params[:game_code]
          @game_name = params[:game_name]
          @frontend = params[:frontend]
          @custom_launch = params[:custom_launch]
          @custom_launch_dir = params[:custom_launch_dir]
          @is_favorite = params[:is_favorite] || false
          @favorite_order = params[:favorite_order]
          @favorite_added = params[:favorite_added]
        end

        def to_h
          {
            user_id: @user_id,
            password: @password,
            char_name: @char_name,
            game_code: @game_code,
            game_name: @game_name,
            frontend: @frontend,
            custom_launch: @custom_launch,
            custom_launch_dir: @custom_launch_dir,
            is_favorite: @is_favorite,
            favorite_order: @favorite_order,
            favorite_added: @favorite_added
          }
        end

        # Checks if the login parameters are marked as favorite.
        # @return [Boolean] true if the parameters are marked as favorite, false otherwise
        def favorite?
          @is_favorite == true
        end

        # Returns a hash representing the character ID information.
        # @return [Hash] a hash containing username, character name, and game code
        def character_id
          {
            username: @user_id,
            char_name: @char_name,
            game_code: @game_code
          }
        end
      end

      # Represents the configuration settings for the user interface.
      #
      # This class encapsulates UI configuration parameters and provides methods to access them.
      class UIConfig
        attr_accessor :theme_state, :tab_layout_state, :autosort_state

        def initialize(params = {})
          @theme_state = params[:theme_state]
          @tab_layout_state = params[:tab_layout_state]
          @autosort_state = params[:autosort_state]
        end

        def to_h
          {
            theme_state: @theme_state,
            tab_layout_state: @tab_layout_state,
            autosort_state: @autosort_state
          }
        end
      end

      # Represents the callback parameters for various UI actions.
      #
      # This class encapsulates callback parameters and provides methods to access them.
      class CallbackParams
        attr_accessor :on_play, :on_remove, :on_save, :on_error,
                      :on_theme_change, :on_layout_change, :on_sort_change,
                      :on_persistent_launcher_change, :on_add_character, :on_favorites_change, :on_favorites_reorder

        # @option params [Proc] :on_play Callback for play button
        # Initializes a new instance of CallbackParams.
        # @param params [Hash] a hash of callback parameters
        # @option params [Proc] :on_play Callback for play button
        # @option params [Proc] :on_remove Callback for remove action
        # @option params [Proc] :on_save Callback for save action
        # @option params [Proc] :on_error Callback for error handling
        # @option params [Proc] :on_theme_change Callback for theme change
        # @option params [Proc] :on_layout_change Callback for layout change
        # @option params [Proc] :on_sort_change Callback for sort change
        # @option params [Proc] :on_persistent_launcher_change Callback for persistent launcher change
        # @option params [Proc] :on_add_character Callback for adding a character
        # @option params [Proc] :on_favorites_change Callback for favorites change
        # @option params [Proc] :on_favorites_reorder Callback for favorites reorder
        # @return [CallbackParams]
        def initialize(params = {})
          @on_play = params[:on_play]
          @on_remove = params[:on_remove]
          @on_save = params[:on_save]
          @on_error = params[:on_error]
          @on_theme_change = params[:on_theme_change]
          @on_layout_change = params[:on_layout_change]
          @on_sort_change = params[:on_sort_change]
          @on_persistent_launcher_change = params[:on_persistent_launcher_change]
          @on_add_character = params[:on_add_character]
          @on_favorites_change = params[:on_favorites_change]
          @on_favorites_reorder = params[:on_favorites_reorder]
        end

        # Converts the CallbackParams instance to a hash representation.
        # @return [Hash] a hash containing the callback parameters
        def to_h
          {
            on_play: @on_play,
            on_remove: @on_remove,
            on_save: @on_save,
            on_error: @on_error,
            on_theme_change: @on_theme_change,
            on_layout_change: @on_layout_change,
            on_sort_change: @on_sort_change,
            on_persistent_launcher_change: @on_persistent_launcher_change,
            on_add_character: @on_add_character,
            on_favorites_change: @on_favorites_change,
            on_favorites_reorder: @on_favorites_reorder
          }
        end
      end
    end
  end
end

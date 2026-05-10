
module Lich
  module Common
    module GUI
      # Represents the parameters required for user login.
      #
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

        def favorite?
          @is_favorite == true
        end

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
      # @see LoginParams
      # @see CallbackParams
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
      # @see LoginParams
      # @see UIConfig
      class CallbackParams
        attr_accessor :on_play, :on_remove, :on_save, :on_error,
                      :on_theme_change, :on_layout_change, :on_sort_change,
                      :on_persistent_launcher_change, :on_add_character, :on_favorites_change, :on_favorites_reorder

        # @option params [Proc] :on_play Callback for play button
        # Initializes a new instance of CallbackParams.
        # @param params [Hash] a hash of callback parameters
        # @param params[:on_play] [Proc] Callback for play button
        # @param params[:on_remove] [Proc] Callback for remove action
        # @param params[:on_save] [Proc] Callback for save action
        # @param params[:on_error] [Proc] Callback for error handling
        # @param params[:on_theme_change] [Proc] Callback for theme change
        # @param params[:on_layout_change] [Proc] Callback for layout change
        # @param params[:on_sort_change] [Proc] Callback for sort change
        # @param params[:on_persistent_launcher_change] [Proc] Callback for persistent launcher change
        # @param params[:on_add_character] [Proc] Callback for adding a character
        # @param params[:on_favorites_change] [Proc] Callback for favorites change
        # @param params[:on_favorites_reorder] [Proc] Callback for reordering favorites
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

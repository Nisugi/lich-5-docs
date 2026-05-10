
# The Lich module provides the main functionality for the Lich 5 project.
# It contains submodules for various features and help text.
module Lich
  module Main
    # The HelpText module provides help text for various topics in the Lich 5 project.
    # It includes methods to render help based on user input.
    # @example Displaying help for login
    #   Lich::Main::HelpText.render('login')
    module HelpText
      # A constant that holds the available help topics.
      # @return [Array<String>] List of help topics.
      HELP_TOPICS = %w[login accounts automation paths advanced].freeze

      # Renders help text for a given topic.
      # @param topic [String, nil] The help topic to render. If nil, defaults to general help.
      # @return [String] The help text for the specified topic.
      # @raise [ArgumentError] If the topic is invalid.
      # @example Rendering help for accounts
      #   Lich::Main::HelpText.render('accounts')
      def self.render(topic = nil)
        normalized_topic = normalize_topic(topic)

        case normalized_topic
        when 'login' then login_help
        when 'accounts' then accounts_help
        when 'automation' then automation_help
        when 'paths' then paths_help
        when 'advanced' then advanced_help
        else
          default_help
        end
      end

      # Extracts the help topic from command line arguments.
      # @param argv [Array<String>] The command line arguments.
      # @param help_arg [String] The help argument to parse.
      # @return [String, nil] The extracted topic or nil if not found.
      # @example Extracting topic from arguments
      #   topic = Lich::Main::HelpText.topic_from_argv(ARGV, '--help=login')
      def self.topic_from_argv(argv, help_arg)
        return help_arg.split('=', 2).last if help_arg.start_with?('--help=')

        help_index = argv.index(help_arg)
        return nil if help_index.nil?

        topic = argv[help_index + 1]
        return nil if topic.nil? || topic.start_with?('--')

        topic
      end

      # Normalizes the topic string to a standard format.
      # @param topic [String, nil] The topic to normalize.
      # @return [String, nil] The normalized topic or nil if invalid.
      # @example Normalizing a topic
      #   normalized = Lich::Main::HelpText.normalize_topic('Login')
      def self.normalize_topic(topic)
        case topic.to_s.downcase
        when '', 'overview' then nil
        when 'account', 'accounts' then 'accounts'
        when 'automation', 'automations', 'sessions', 'diagnostics' then 'automation'
        when 'login' then 'login'
        when 'path', 'paths' then 'paths'
        when 'advanced', 'compat', 'compatibility' then 'advanced'
        else
          nil
        end
      end

      # Provides the default help text when no specific topic is requested.
      # @return [String] The default help text.
      # @example Getting default help text
      #   help_text = Lich::Main::HelpText.default_help
      def self.default_help
        <<~TEXT
          Lich 5
          Usage:
            lich [command] [options]

          Most common:
            lich --login CHARACTER
            lich --login CHARACTER --headless PORT
            lich --login CHARACTER --headless auto
            lich --add-account ACCOUNT PASSWORD

          Help topics:
            lich --help login
            lich --help accounts
            lich --help automation
            lich --help paths
            lich --help advanced

          General:
            --help                  Show help
            --version               Show version
        TEXT
      end

      # Provides help text specific to the login command.
      # @return [String] The help text for login options.
      # @example Getting login help text
      #   help_text = Lich::Main::HelpText.login_help
      def self.login_help
        <<~TEXT
          Lich Help: login

          Usage:
            lich --login CHARACTER [options]

          Login options:
            --login CHARACTER       Login using a saved entry
            --headless PORT         Run without a frontend and expose a detachable client on PORT
            --headless auto         Run without a frontend and let the OS assign a detachable port
            --start-scripts=LIST    Start scripts after login (comma-separated)
            --save                  Save successful CLI login details to entry.yaml
            --reconnect             Reconnect automatically if the session drops
            --reconnect-delay=SPEC  Delay before reconnecting

          Game selection:
            --gemstone, --gs
            --dragonrealms, --dr
            --shattered
            --fallen
            --platinum
            --test

          Frontend selection:
            --wizard
            --stormfront
            --avalon
            --frostbite
            --genie

          Advanced launch:
            --custom-launch=NAME
            --detachable-client=PORT
            --dark-mode=true|false
            --game=HOST:PORT

          Examples:
            lich --login Mychar
            lich --login Mychar --gemstone --shattered
            lich --login Mychar --frostbite
            lich --login Mychar --headless 8001
            lich --login Mychar --headless auto
            lich --login Mychar --start-scripts=repository,go2
        TEXT
      end

      # Provides help text specific to account management commands.
      # @return [String] The help text for account commands.
      # @example Getting accounts help text
      #   help_text = Lich::Main::HelpText.accounts_help
      def self.accounts_help
        <<~TEXT
          Lich Help: accounts

          Usage:
            lich [account command] [options]

          Commands:
            --add-account ACCOUNT PASSWORD
            --change-account-password ACCOUNT NEWPASSWORD
            --change-master-password OLDPASSWORD [NEWPASSWORD]
            --recover-master-password [NEWPASSWORD]
            --convert-entries MODE
            --change-encryption-mode MODE [--master-password PASSWORD]

          Modes:
            plaintext
            standard
            enhanced

          Examples:
            lich --add-account MYACCOUNT MYPASSWORD --frontend stormfront
            lich --change-account-password MYACCOUNT NEWPASSWORD
            lich --convert-entries enhanced
            lich --change-encryption-mode enhanced --master-password SECRET
        TEXT
      end

      # Provides help text specific to automation commands.
      # @return [String] The help text for automation commands.
      # @example Getting automation help text
      #   help_text = Lich::Main::HelpText.automation_help
      def self.automation_help
        <<~TEXT
          Lich Help: automation

          Usage:
            lich [automation command]

          Commands:
            --active-sessions       List live sessions
            --session-info NAME     Show live session details for NAME

          Examples:
            lich --active-sessions
            lich --session-info Mychar
        TEXT
      end

      # Provides help text specific to path options.
      # @return [String] The help text for path options.
      # @example Getting paths help text
      #   help_text = Lich::Main::HelpText.paths_help
      def self.paths_help
        <<~TEXT
          Lich Help: paths

          Usage:
            lich [options]

          Path options:
            --home=PATH
            --script-dir=PATH
            --data-dir=PATH
            --temp-dir=PATH
            --hosts-dir=PATH
            --hosts-file=PATH

          Examples:
            lich --script-dir=/my/scripts
            lich --data-dir=/my/data --temp-dir=/tmp/lich
        TEXT
      end

      # Provides help text for advanced options and compatibility flags.
      # @return [String] The help text for advanced options.
      # @example Getting advanced help text
      #   help_text = Lich::Main::HelpText.advanced_help
      def self.advanced_help
        <<~TEXT
          Lich Help: advanced

          Compatibility / advanced options:
            --gui
            --no-gui
            --without-frontend
            --detachable-client=PORT
            --frontend=NAME
            --frontend-command=CMD
            --game=HOST:PORT

          Notes:
            Prefer --headless PORT or --headless auto for new headless launches.
            Compatibility flags remain supported but are intentionally omitted from the default help screen.
        TEXT
      end
    end
  end
end

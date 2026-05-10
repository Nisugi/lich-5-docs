# frozen_string_literal: true

require_relative 'password_cipher'
require_relative '../authentication/entry_store'

module Lich
  module Common
    module GUI
      module PasswordManager
        # Changes the password for a given entry based on the specified encryption mode.
        #
        # @param entry [Hash] the entry containing the password and encryption mode
        # @param new_password [String] the new password to set
        # @param account_name [String, nil] optional account name for standard mode
        # @param master_password [String, nil] optional master password for enhanced mode
        # @return [Hash] the updated entry with the new password
        # @raise [ArgumentError] if required parameters are missing for the specified mode
        # @raise [NotImplementedError] if the ssh_key mode is used
        # @raise [ArgumentError] if an unknown encryption mode is specified
        def self.change_password(entry:, new_password:, account_name: nil, master_password: nil)
          mode = entry[:encryption_mode]&.to_sym || :plaintext

          case mode
          when :plaintext
            # Plaintext mode - store password directly
            entry[:password] = new_password
          when :standard
            # Standard mode - encrypt with account name
            raise ArgumentError, 'account_name required for standard mode' if account_name.nil?

            entry[:password] = PasswordCipher.encrypt(
              new_password,
              mode: :standard,
              account_name: account_name
            )
          when :enhanced
            # Enhanced encryption mode - encrypt with master password
            raise ArgumentError, 'master_password required for enhanced mode' if master_password.nil?

            entry[:password] = PasswordCipher.encrypt(
              new_password,
              mode: :enhanced,
              master_password: master_password
            )
          when :ssh_key
            # Certificate encryption mode - future feature, not yet implemented
            raise NotImplementedError, "#{mode} mode not yet implemented"
          else
            raise ArgumentError, "Unknown encryption mode: #{mode}"
          end

          entry
        end

        # Retrieves the password for a given entry based on the specified encryption mode.
        #
        # @param entry [Hash] the entry containing the encrypted password and encryption mode
        # @param account_name [String, nil] optional account name for standard mode
        # @param master_password [String, nil] optional master password for enhanced mode
        # @return [String] the decrypted or plaintext password
        # @raise [ArgumentError] if required parameters are missing for the specified mode
        # @raise [NotImplementedError] if the ssh_key mode is used
        # @raise [ArgumentError] if an unknown encryption mode is specified
        def self.get_password(entry:, account_name: nil, master_password: nil)
          mode = entry[:encryption_mode]&.to_sym || :plaintext
          encrypted_password = entry[:password]

          case mode
          when :plaintext
            # Plaintext mode - return password directly
            encrypted_password
          when :standard
            # Standard mode - decrypt with account name
            raise ArgumentError, 'account_name required for standard mode' if account_name.nil?

            PasswordCipher.decrypt(
              encrypted_password,
              mode: :standard,
              account_name: account_name
            )
          when :enhanced
            # Enhanced encryption mode - decrypt with master password
            raise ArgumentError, 'master_password required for enhanced mode' if master_password.nil?

            PasswordCipher.decrypt(
              encrypted_password,
              mode: :enhanced,
              master_password: master_password
            )
          when :ssh_key
            # Certificate encryption mode - future feature, not yet implemented
            raise NotImplementedError, "#{mode} mode not yet implemented"
          else
            raise ArgumentError, "Unknown encryption mode: #{mode}"
          end
        end
      end
    end
  end
end

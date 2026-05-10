# frozen_string_literal: true

require 'openssl'
require 'securerandom'
require 'base64'

# Lich module provides common functionalities for the application.
# @example Including the Lich module
#   include Lich
module Lich
  module Common
    module GUI
      # PasswordCipher module handles encryption and decryption of passwords.
      # @example Encrypting a password
      #   encrypted = PasswordCipher.encrypt("my_password", mode: :standard, account_name: "user")
      module PasswordCipher
        class DecryptionError < StandardError; end

        # AES cipher algorithm
        # AES cipher algorithm used for encryption and decryption.
        CIPHER_ALGORITHM = 'AES-256-CBC'

        # PBKDF2 iteration count for key derivation
        # PBKDF2 iteration count for key derivation.
        KEY_ITERATIONS = 10_000

        # Key length for AES-256 (32 bytes = 256 bits)
        # Key length for AES-256 (32 bytes = 256 bits).
        KEY_LENGTH = 32

        # Encrypts a password using the specified mode and parameters.
        # @param password [String] The password to encrypt.
        # @param mode [Symbol] The encryption mode, either :standard or :enhanced.
        # @param account_name [String, nil] The account name for standard mode (required).
        # @param master_password [String, nil] The master password for enhanced mode (required).
        # @return [String] The encrypted password encoded in Base64.
        # @raise ArgumentError if the parameters are invalid.
        # @example Encrypting a password
        #   encrypted = PasswordCipher.encrypt("my_password", mode: :standard, account_name: "user")
        def self.encrypt(password, mode:, account_name: nil, master_password: nil)
          validate_encryption_params(mode, account_name, master_password)

          # Derive encryption key based on mode
          key = derive_key(mode, account_name, master_password)

          # Initialize cipher
          cipher = OpenSSL::Cipher.new(CIPHER_ALGORITHM)
          cipher.encrypt
          cipher.key = key

          # Generate random IV
          iv = cipher.random_iv

          # Encrypt password
          encrypted = cipher.update(password) + cipher.final

          # Combine IV + encrypted data and encode as Base64
          Base64.strict_encode64(iv + encrypted)
        end

        # Decrypts an encrypted password using the specified mode and parameters.
        # @param encrypted_password [String] The encrypted password to decrypt.
        # @param mode [Symbol] The encryption mode, either :standard or :enhanced.
        # @param account_name [String, nil] The account name for standard mode (required).
        # @param master_password [String, nil] The master password for enhanced mode (required).
        # @return [String] The decrypted password.
        # @raise ArgumentError if the parameters are invalid.
        # @raise DecryptionError if decryption fails.
        # @example Decrypting a password
        #   decrypted = PasswordCipher.decrypt(encrypted, mode: :standard, account_name: "user")
        def self.decrypt(encrypted_password, mode:, account_name: nil, master_password: nil)
          validate_encryption_params(mode, account_name, master_password)

          # Derive decryption key based on mode
          key = derive_key(mode, account_name, master_password)

          # Decode from Base64
          encrypted_data = Base64.strict_decode64(encrypted_password)

          # Extract IV and ciphertext
          cipher = OpenSSL::Cipher.new(CIPHER_ALGORITHM)
          iv_length = cipher.iv_len
          iv = encrypted_data[0...iv_length]
          ciphertext = encrypted_data[iv_length..]

          # Initialize cipher for decryption
          cipher.decrypt
          cipher.key = key
          cipher.iv = iv

          # Decrypt password
          decrypted = cipher.update(ciphertext) + cipher.final
          decrypted.force_encoding('UTF-8')
        rescue OpenSSL::Cipher::CipherError, ArgumentError => e
          raise DecryptionError, "Failed to decrypt password: #{e.message}"
        end

        def self.validate_encryption_params(mode, account_name, master_password)
          unless %i[standard enhanced].include?(mode)
            raise ArgumentError, "Unsupported encryption mode: #{mode}"
          end

          if mode == :standard && account_name.nil?
            raise ArgumentError, 'account_name required for :standard mode'
          end

          if mode == :enhanced && master_password.nil?
            raise ArgumentError, 'master_password required for :enhanced mode'
          end
        end
        private_class_method :validate_encryption_params

        def self.derive_key(mode, account_name, master_password)
          # Select passphrase based on mode
          passphrase = case mode
                       when :standard
                         account_name.upcase
                       when :enhanced
                         master_password
                       end

          # Use a fixed salt for deterministic key derivation
          # In production, consider using a stored random salt per account
          salt = "lich5-password-encryption-#{mode}"

          # Derive key using PBKDF2
          OpenSSL::PKCS5.pbkdf2_hmac(
            passphrase,
            salt,
            KEY_ITERATIONS,
            KEY_LENGTH,
            OpenSSL::Digest.new('SHA256')
          )
        end
        private_class_method :derive_key
      end
    end
  end
end

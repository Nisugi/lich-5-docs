# frozen_string_literal: true

Lich::Util.install_gem_requirements({ 'ffi' => true })

# Provides utility functions and classes for the Lich project.
#
# @see Lich::Util
module Lich
  module Common
    module GUI
      # Provides access to Windows Credential Manager functions using FFI.
      #
      # This module allows storing, retrieving, and deleting credentials on Windows systems.
      #
      # @see Lich::Common::GUI
      module WindowsCredentialManager
        extend FFI::Library

        # Load advapi32.dll and kernel32.dll for Credential Manager functions (Windows only)
        if OS.windows?
          ffi_lib 'advapi32', 'kernel32'
        end

        # CRED_TYPE values
        CRED_TYPE_GENERIC = 1
        CRED_TYPE_DOMAIN_PASSWORD = 2
        CRED_TYPE_DOMAIN_CERTIFICATE = 3
        CRED_TYPE_DOMAIN_VISIBLE_PASSWORD = 4
        CRED_TYPE_GENERIC_CERTIFICATE = 5
        CRED_TYPE_DOMAIN_EXTENDED = 6

        # CRED_PERSIST values
        CRED_PERSIST_SESSION = 1
        CRED_PERSIST_LOCAL_MACHINE = 2
        CRED_PERSIST_ENTERPRISE = 3

        # Max credential size (512KB)
        CRED_MAX_CREDENTIAL_BLOB_SIZE = 512 * 1024

        # Represents the structure of a credential in Windows Credential Manager.
        #
        # This class defines the layout of the credential structure used in FFI calls.
        class CredentialStruct < FFI::Struct
          layout(
            :flags, :uint32,
            :type, :uint32,
            :target_name, :pointer,
            :comment, :pointer,
            :last_written, :uint64,
            :credential_blob_size, :uint32,
            :credential_blob, :pointer,
            :persist, :uint32,
            :attribute_count, :uint32,
            :attributes, :pointer,
            :target_alias, :pointer,
            :user_name, :pointer
          )
        end

        # FFI function definitions (Windows only)
        if OS.windows?
          attach_function :CredReadW, [:pointer, :uint32, :uint32, :pointer], :bool
          attach_function :CredWriteW, [:pointer, :uint32], :bool
          attach_function :CredDeleteW, [:pointer, :uint32, :uint32], :bool
          attach_function :CredFree, [:pointer], :void
          attach_function :GetLastError, [], :uint32
        end

        class << self
          # Checks if the Windows Credential Manager is available.
          #
          # @return [Boolean] true if available, false otherwise.
          def available?
            return false unless OS.windows?

            # Simple test: try to allocate credential structure
            begin
              FFI::MemoryPointer.new(CredentialStruct)
              true
            rescue
              false
            end
          end

          # Stores a credential in the Windows Credential Manager.
          #
          # @param target_name [String] the target name for the credential.
          # @param username [String] the username associated with the credential.
          # @param password [String] the password to store.
          # @param comment [String, nil] an optional comment for the credential.
          # @param persist [Integer] the persistence type (default is CRED_PERSIST_LOCAL_MACHINE).
          # @return [Boolean] true if the credential was stored successfully, false otherwise.
          def store_credential(target_name, username, password, comment = nil, persist = CRED_PERSIST_LOCAL_MACHINE)
            return false unless available?

            begin
              credential = CredentialStruct.new

              # Convert strings to wide characters (UTF-16LE)
              target_name_wide = string_to_wide(target_name)
              username_wide = string_to_wide(username)
              # Store password as UTF-8 bytes (as binary data, not text)
              password_bytes = password.to_s.encode('UTF-8')
              password_blob = password_bytes.b
              comment_wide = comment ? string_to_wide(comment) : FFI::Pointer.new(:pointer, 0)

              Lich.log "debug: Storing credential - target: #{target_name}, user: #{username}, pass_size: #{password_blob.bytesize}, persist: #{persist}"

              # Allocate memory for credential blob (password data)
              blob_ptr = FFI::MemoryPointer.new(:uint8, password_blob.bytesize)
              blob_ptr.put_bytes(0, password_blob)

              # Fill credential structure
              credential[:flags] = 0
              credential[:type] = CRED_TYPE_GENERIC
              credential[:target_name] = target_name_wide
              credential[:comment] = comment_wide
              credential[:credential_blob_size] = password_blob.size
              credential[:credential_blob] = blob_ptr
              credential[:persist] = persist
              credential[:attribute_count] = 0
              credential[:attributes] = FFI::Pointer.new(:pointer, 0)
              credential[:user_name] = username_wide

              # Call CredWriteW - pass pointer to the credential struct
              result = CredWriteW(credential, 0)

              if result
                Lich.log "debug: Credential stored successfully"
                true
              else
                error_code = GetLastError
                Lich.log "error: CredWriteW failed with error code #{error_code}"
                false
              end
            rescue StandardError => e
              Lich.log "error: Failed to store credential: #{e.class.name}: #{e.message}"
              false
            end
          end

          # Retrieves a credential from the Windows Credential Manager.
          #
          # @param target_name [String] the target name of the credential to retrieve.
          # @return [String, nil] the password if found, nil if not found.
          def retrieve_credential(target_name)
            return nil unless available?

            begin
              target_name_wide = string_to_wide(target_name)
              cred_ptr = FFI::MemoryPointer.new(:pointer)

              # Call CredReadW
              result = CredReadW(target_name_wide, CRED_TYPE_GENERIC, 0, cred_ptr)

              if result
                cred = cred_ptr.read_pointer
                credential = CredentialStruct.new(cred)

                # Extract password blob
                blob_ptr = credential[:credential_blob]
                blob_size = credential[:credential_blob_size]
                password_blob = blob_ptr.read_bytes(blob_size)
                # Password blob is stored as UTF-8 bytes; convert safely with encoding handling
                password = password_blob.b.force_encoding('UTF-8')

                # Free credential structure
                CredFree(cred)

                password
              else
                error_code = GetLastError
                # ERROR_NOT_FOUND = 1168, so only log unexpected errors
                Lich.log "error: CredReadW failed with error code #{error_code}" unless error_code == 1168
                nil
              end
            rescue StandardError
              # Don't log as error for "not found" - it's expected on first run
              # Only actual failures (encoding, access, API errors) should log
              nil
            end
          end

          # Deletes a credential from the Windows Credential Manager.
          #
          # @param target_name [String] the target name of the credential to delete.
          # @return [Boolean] true if the credential was deleted successfully, false otherwise.
          def delete_credential(target_name)
            return false unless available?

            begin
              target_name_wide = string_to_wide(target_name)

              # Call CredDeleteW
              result = CredDeleteW(target_name_wide, CRED_TYPE_GENERIC, 0)

              if result
                true
              else
                error_code = GetLastError
                Lich.log "error: CredDeleteW failed with error code #{error_code}"
                false
              end
            rescue StandardError => e
              Lich.log "error: Failed to delete credential: #{e.message}"
              false
            end
          end

          private

          # Converts a string to a wide character string (UTF-16LE).
          #
          # @param str [String] the string to convert.
          # @return [FFI::MemoryPointer] a pointer to the wide character string.
          def string_to_wide(str)
            wide_str = str.encode('UTF-16LE')
            # Add UTF-16LE null terminator
            null_term = "\x00\x00".b.force_encoding('UTF-16LE')
            wide_str_with_null = wide_str + null_term
            ptr = FFI::MemoryPointer.new(:uint8, wide_str_with_null.bytesize)
            ptr.put_bytes(0, wide_str_with_null)
            ptr
          end

          # Converts a wide character string (UTF-16LE) back to a regular string.
          #
          # @param ptr [FFI::MemoryPointer] a pointer to the wide character string.
          # @return [String, nil] the converted string, or nil if the pointer is null.
          def wide_to_string(ptr)
            return nil if ptr.null?

            # Read until null terminator
            size = 0
            loop do
              byte1 = ptr.get_uint8(size)
              byte2 = ptr.get_uint8(size + 1)
              break if byte1 == 0 && byte2 == 0

              size += 2
            end

            wide_bytes = ptr.read_bytes(size)
            wide_bytes.force_encoding('UTF-16LE').encode('UTF-8')
          end
        end
      end
    end
  end
end

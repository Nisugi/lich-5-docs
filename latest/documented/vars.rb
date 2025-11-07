# Carve out module Vars (should this be in settings path?)
# 2024-06-13

module Lich
  module Common
    # Provides a storage mechanism for variables in the Lich application.
    # This module allows for loading, saving, and accessing variables in a thread-safe manner.
    # @example Accessing a variable
    #   value = Lich::Common::Vars[:my_variable]
    module Vars
      @@vars   = Hash.new
      md5      = nil
      @@loaded = false
      @@load = proc {
        Lich.db_mutex.synchronize {
          unless @@loaded
            begin
              h = Lich.db.get_first_value('SELECT hash FROM uservars WHERE scope=?;', ["#{XMLData.game}:#{XMLData.name}".encode('UTF-8')])
            rescue SQLite3::BusyException
              sleep 0.1
              retry
            end
            if h
              begin
                hash = Marshal.load(h)
                hash.each { |k, v| @@vars[k] = v }
                md5 = Digest::MD5.hexdigest(hash.to_s)
              rescue
                respond "--- Lich: error: #{$!}"
                respond $!.backtrace[0..2]
              end
            end
            @@loaded = true
          end
        }
        nil
      }
      @@save = proc {
        Lich.db_mutex.synchronize {
          if @@loaded
            if Digest::MD5.hexdigest(@@vars.to_s) != md5
              md5 = Digest::MD5.hexdigest(@@vars.to_s)
              blob = SQLite3::Blob.new(Marshal.dump(@@vars))
              begin
                Lich.db.execute('INSERT OR REPLACE INTO uservars(scope,hash) VALUES(?,?);', ["#{XMLData.game}:#{XMLData.name}".encode('UTF-8'), blob])
              rescue SQLite3::BusyException
                sleep 0.1
                retry
              end
            end
          end
        }
        nil
      }
      Thread.new {
        loop {
          sleep 300
          begin
            @@save.call
          rescue
            Lich.log "error: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
            respond "--- Lich: error: #{$!}\n\t#{$!.backtrace[0..1].join("\n\t")}"
          end
        }
      }
      # Retrieves the value of a variable by name.
      # @param name [Symbol] The name of the variable to retrieve.
      # @return [Object] The value associated with the variable name.
      # @raise [RuntimeError] If the variable is not loaded yet.
      # @example Getting a variable
      #   value = Lich::Common::Vars[:my_variable]
      def Vars.[](name)
        @@load.call unless @@loaded
        @@vars[name]
      end

      # Sets the value of a variable by name.
      # @param name [Symbol] The name of the variable to set.
      # @param val [Object] The value to assign to the variable. If nil, the variable is deleted.
      # @return [void]
      # @raise [RuntimeError] If the variable is not loaded yet.
      # @example Setting a variable
      #   Lich::Common::Vars[:my_variable] = 'new_value'
      def Vars.[]=(name, val)
        @@load.call unless @@loaded
        if val.nil?
          @@vars.delete(name)
        else
          @@vars[name] = val
        end
      end

      # Returns a duplicate of all stored variables.
      # @return [Hash] A hash containing all variable names and their values.
      # @raise [RuntimeError] If the variables are not loaded yet.
      # @example Listing all variables
      #   all_vars = Lich::Common::Vars.list
      def Vars.list
        @@load.call unless @@loaded
        @@vars.dup
      end

      # Saves the current state of variables to the database.
      # @return [void]
      # @raise [RuntimeError] If the variables are not loaded yet.
      # @example Saving variables
      #   Lich::Common::Vars.save
      def Vars.save
        @@save.call
      end

      # Handles dynamic method calls for setting and getting variables.
      # @param arg1 [Symbol] The name of the variable or the method being called.
      # @param arg2 [Object] The value to set if the method is a setter.
      # @return [Object, nil] The value of the variable if getting, otherwise nil.
      # @raise [RuntimeError] If the variables are not loaded yet.
      # @example Dynamic variable access
      #   Lich::Common::Vars.my_variable = 'value'
      #   value = Lich::Common::Vars.my_variable
      def Vars.method_missing(arg1, arg2 = '')
        @@load.call unless @@loaded
        if arg1[-1, 1] == '='
          if arg2.nil?
            @@vars.delete(arg1.to_s.chop)
          else
            @@vars[arg1.to_s.chop] = arg2
          end
        else
          @@vars[arg1.to_s]
        end
      end
    end
  end
end

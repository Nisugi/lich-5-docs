# frozen_string_literal: true

require 'rbconfig'

find_wine_binary = lambda {
  exe_ext = RbConfig::CONFIG['EXEEXT'].to_s
  extensions = exe_ext.empty? ? [''] : [exe_ext, '']

  ENV.fetch('PATH', '').split(File::PATH_SEPARATOR).each do |dir|
    next if dir.nil? || dir.empty?

    extensions.each do |ext|
      candidate = File.join(dir, "wine#{ext}")
      return candidate if File.file?(candidate) && File.executable?(candidate)
    end
  end

  nil
}

# Detect Wine runtime configuration from CLI overrides or PATH lookup.
# `--no-wine` and `--without-frontend` explicitly disable detection.
if (arg = ARGV.find { |a| a =~ /^--wine=.+$/i })
  $wine_bin = arg.sub(/^--wine=/i, '')
elsif ARGV.find { |a| a =~ /^--no-wine$/i } || ARGV.include?('--without-frontend')
  $wine_bin = nil
else
  $wine_bin = find_wine_binary.call
end

unless $wine_bin.nil?
  if (arg = ARGV.find { |a| a =~ /^--wine-prefix=.+$/i })
    $wine_prefix = arg.sub(/^--wine-prefix=/i, '')
  elsif ENV['WINEPREFIX']
    $wine_prefix = ENV['WINEPREFIX']
  elsif ENV['HOME']
    $wine_prefix = ENV['HOME'] + '/.wine'
  else
    $wine_prefix = nil
  end

  if $wine_bin and File.exist?($wine_bin) and File.file?($wine_bin) and $wine_prefix and File.exist?($wine_prefix) and File.directory?($wine_prefix)
    # Module for interacting with Wine registry
    # This module provides methods to get and set values in the Wine registry.
    # @example Getting a registry value
    #   value = Wine.registry_gets("HKEY_CURRENT_USER\Software\MyApp\Setting")
    module Wine
      # The path to the Wine binary.
      # This constant holds the path to the Wine executable determined at runtime.
      BIN = $wine_bin
      # The Wine prefix path.
      # This constant holds the path to the Wine prefix determined at runtime.
      PREFIX = $wine_prefix

      # Retrieves a value from the Wine registry.
      # @param key [String] The registry key in the format "HKEY_LOCAL_MACHINE\Subkey\Value"
      # @return [String, false] The value associated with the key, or false if not found.
      # @raise [ArgumentError] If the key format is invalid.
      # @example Getting a registry value
      #   value = Wine.registry_gets("HKEY_CURRENT_USER\Software\MyApp\Setting")
      def Wine.registry_gets(key)
        match_data = /(HKEY_LOCAL_MACHINE|HKEY_CURRENT_USER)\\(.+)\\([^\\]*)/.match(key)
        raise ArgumentError, "Invalid registry key format: #{key.inspect}" unless match_data

        hkey, subkey, thingie = match_data.captures # fixme: stupid highlights ]/
        if File.exist?(PREFIX + '/system.reg')
          if hkey == 'HKEY_LOCAL_MACHINE'
            subkey = "[#{subkey.gsub('\\', '\\\\\\')}]"
            if thingie.nil? or thingie.empty?
              thingie = '@'
            else
              thingie = "\"#{thingie}\""
            end
            lookin = result = false
            File.open(PREFIX + '/system.reg') { |f| f.readlines }.each { |line|
              if line[0...subkey.length] == subkey
                lookin = true
              elsif line =~ /^\[/
                lookin = false
              elsif lookin
                value_match = /^#{thingie}="(.*)"$/i.match(line)
                next unless value_match

                result = value_match[1].split('\\"').join('"').split('\\\\').join('\\').sub(/\\0$/, '')
                break
              end
            }
            return result
          else
            return false
          end
        else
          return false
        end
      end

      # Sets a value in the Wine registry.
      # @param key [String] The registry key in the format "HKEY_LOCAL_MACHINE\Subkey\Value"
      # @param value [String] The value to set for the specified key.
      # @return [Boolean] True if the operation succeeded, false otherwise.
      # @raise [ArgumentError] If the key format is invalid.
      # @example Setting a registry value
      #   success = Wine.registry_puts("HKEY_CURRENT_USER\Software\MyApp\Setting", "NewValue")
      def Wine.registry_puts(key, value)
        match_data = /(HKEY_LOCAL_MACHINE|HKEY_CURRENT_USER)\\(.+)\\([^\\]*)/.match(key)
        raise ArgumentError, "Invalid registry key format: #{key.inspect}" unless match_data

        hkey, subkey, thingie = match_data.captures # fixme ]/
        if File.exist?(PREFIX)
          if thingie.nil? or thingie.empty?
            thingie = '@'
          else
            thingie = "\"#{thingie}\""
          end
          # gsub sucks for this..
          value = value.split('\\').join('\\\\')
          value = value.split('"').join('\"')
          filename = nil
          begin
            regedit_data = "REGEDIT4\n\n[#{hkey}\\#{subkey}]\n#{thingie}=\"#{value}\"\n\n"
            filename = "#{TEMP_DIR}/wine-#{Time.now.to_i}.reg"
            File.open(filename, 'w') { |f| f.write(regedit_data) }
            succeeded = system(BIN, 'regedit', filename)
            return false unless succeeded
            sleep 0.2
          rescue StandardError
            return false
          ensure
            File.delete(filename) if filename && File.exist?(filename)
          end
          return true
        end
        false
      end
    end
  end
end

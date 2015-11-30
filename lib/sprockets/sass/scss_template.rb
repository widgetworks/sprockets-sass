module Sprockets
  module Sass
  	
  	class SourcemapCache
  		
  		@@cache = {}
  		
  		
  		def self.set_cache(new_cache)
  			@@cache = new_cache
  		end
  		
  		
  		def self.get_cache
  			@@cache
  		end
  		
  		
  		def self.add(key, value)
  			@@cache[key] = value
  		end
  		
  		
  		def self.get(key)
  			@@cache[key]
  		end
  		
  		
  		def self.has_key?(key)
  			@@cache.has_key?(key)
  		end
  		
  		
  	end
  	
  	
  	
    class ScssTemplate < SassTemplate
      self.default_mime_type = 'text/css'
      
      # Define the expected syntax for the template
      def syntax
        :scss
      end
      
      # See `Tilt::Template#evaluate`.
      def evaluate(context, locals, &block)
        @output ||= begin
			@context = context

			# puts "\nscss_template evaluate\n\n"
			# puts "filename: #{eval_file}"
			#puts "root: #{context.environment.config.root}\n"
			# puts "methods: " + (context.methods.sort - Object.methods).join("\n") + "\n==========\n\n"
			
			# Check the config value to see if we should generate the sourcemap.
			
			puts "sourcemap: #{context.environment.machined.config.sass_sourcemap}"
			
			if (context.environment.machined.config.sass_sourcemap == true)
				puts "### with sourcemap"
				
				# Strip out .erb from filename.
				# mapName = File.basename(eval_file.sub(/\.erb/, ''), '.scss') + '.map'
				
				# Replace .scss with .map so we can detect when map files are requested.
				# mapName = File.basename(eval_file, '.scss') + '.map'
				mapName = File.basename(eval_file) + '.map'

				# Generate the css with sourcemaps relative to the invoked file.
				css, sourcemap = ::Sass::Engine.new(data, sass_options).render_with_sourcemap(mapName)
				
				# Render and store the sourcemap.
				mapJson = sourcemap.to_json(
					:type => :auto,
					:css_path => eval_file,
					:sourcemap_path => eval_file + '.map'
				)
				SourcemapCache.add(mapName, mapJson)
				
			else
				puts "!!! without sourcemap"
				
				css = ::Sass::Engine.new(data, sass_options).render
			end
			
			css
          
        rescue ::Sass::SyntaxError => e
          # Annotates exception message with parse line number
          context.__LINE__ = e.sass_backtrace.first[:line]
          raise e
        end
      end
      
    end
  end
end

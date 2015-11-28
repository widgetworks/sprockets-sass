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

			puts "\nscss_template evaluate\n\n"
			puts "filename: #{eval_file}"
			puts "root: #{context.environment.config.root}\n"
			# puts "methods: " + (context.methods.sort - Object.methods).join("\n") + "\n==========\n\n"

			# NOTE: Strip out .erb from filename.
			mapName = File.basename(eval_file.sub(/\.erb/, ''), '.scss') + '.map'
			# mapName = File.basename(eval_file.sub(/\.erb/, ''), '.scss') + '?sourcemap=1'

			css, sourcemap = ::Sass::Engine.new(data, sass_options).render_with_sourcemap(mapName)
			
			## TODO: Render the sourcemap.
			# Generate the css with sourcemaps relative to the invoked file.
			mapJson = sourcemap.to_json(
				:type => :auto,
				:css_path => eval_file,
				:sourcemap_path => eval_file + '.map'
			)
			SourcemapCache.add(mapName, mapJson)
			
			
			css
			# ::Sass::Engine.new(data, sass_options).render
          
        rescue ::Sass::SyntaxError => e
          # Annotates exception message with parse line number
          context.__LINE__ = e.sass_backtrace.first[:line]
          raise e
        end
      end
      
    end
  end
end

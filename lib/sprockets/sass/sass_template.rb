require 'tilt'

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
    
    
    class SassTemplate < Tilt::SassTemplate
      self.default_mime_type = 'text/css'

      # A reference to the current Sprockets context
      attr_reader :context

      # Determines if the Sass functions have been initialized.
      # They can be 'initialized' without actually being added.
      @sass_functions_initialized = false
      class << self
        attr_accessor :sass_functions_initialized
        alias :sass_functions_initialized? :sass_functions_initialized

        # Templates are initialized once the functions are added.
        def engine_initialized?
          super && sass_functions_initialized?
        end
      end

      # Add the Sass functions if they haven't already been added.
      def initialize_engine
        super unless self.class.superclass.engine_initialized?

        if Sass.add_sass_functions != false
          begin
            require 'sprockets/helpers'
            require 'sprockets/sass/functions'
          rescue LoadError; end
        end

        self.class.sass_functions_initialized = true
      end

      # Define the expected syntax for the template
      def syntax
        :sass
      end

      # See `Tilt::Template#prepare`.
      def prepare
        @context = nil
        @output  = nil
      end

      # See `Tilt::Template#evaluate`.
      def evaluate(context, locals, &block)
        @output ||= begin
          @context = context
          render_content(context, locals)
        rescue ::Sass::SyntaxError => e
          # Annotates exception message with parse line number
          context.__LINE__ = e.sass_backtrace.first[:line]
          raise e
        end
      end

      protected
      
      # Custom function to render with sourcemaps (if enabled in config)
      def render_content(context, locals)
        # puts "\nscss_template evaluate\n\n"
        # puts "filename: #{eval_file}"
        #puts "root: #{context.environment.config.root}\n"
        # puts "methods: " + (context.methods.sort - Object.methods).join("\n") + "\n==========\n\n"
        
        # Check the config value to see if we should generate the sourcemap.
        #puts "sourcemap: #{context.environment.machined.config.sass_sourcemap}"
        has_machined = context.environment.respond_to?(:machined)
        if (has_machined && context.environment.machined.config.sass_sourcemap == true)
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
      end
      
      # Returns a Sprockets-aware cache store for Sass::Engine.
      def cache_store
        return nil if context.environment.cache.nil?

        if defined?(Sprockets::SassCacheStore)
          Sprockets::SassCacheStore.new context.environment
        else
          CacheStore.new context.environment
        end
      end

      # Assemble the options for the `Sass::Engine`
      def sass_options
        # Allow the use of custom SASS importers, making sure the
        # custom importer is a `Sprockets::Sass::Importer`
        if default_sass_options.has_key?(:importer) &&
           default_sass_options[:importer].is_a?(Importer)
          importer = default_sass_options[:importer]
        else
          importer = Importer.new
        end

        merge_sass_options(default_sass_options, options).merge(
          :filename    => eval_file,
          :line        => line,
          :syntax      => syntax,
          :cache_store => cache_store,
          :importer    => importer,
          :custom      => { :sprockets_context => context }
        )
      end

      # Get the default, global Sass options. Start with Compass's
      # options, if it's available.
      def default_sass_options
        if defined?(Compass)
          merge_sass_options Compass.sass_engine_options.dup, Sprockets::Sass.options
        else
          Sprockets::Sass.options.dup
        end
      end

      # Merges two sets of `Sass::Engine` options, prepending
      # the `:load_paths` instead of clobbering them.
      def merge_sass_options(options, other_options)
        if (load_paths = options[:load_paths]) && (other_paths = other_options[:load_paths])
          other_options[:load_paths] = other_paths + load_paths
        end
        options.merge other_options
      end
    end
  end
end

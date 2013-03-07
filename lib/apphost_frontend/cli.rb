require 'optparse'
module AppHost
  module Frontend
    class Options
      def parse!(args)
	options = {}
	opt_parser = OptionParser.new("", 24, '  ') do |opts|
	  opts.banner = "Usage: rackup [ruby options] [rack options]"

	  opts.separator ""
	  opts.separator "Ruby options:"

	  lineno = 1
	  opts.on("-e", "--eval LINE", "evaluate a LINE of code") { |line|
	    eval line, TOPLEVEL_BINDING, "-e", lineno
	    lineno += 1
	  }

	  opts.on("-d", "--debug", "set debugging flags (set $DEBUG to true)") {
	    options[:debug] = true
	  }
	  opts.on("-w", "--warn", "turn warnings on for your script") {
	    options[:warn] = true
	  }

	  opts.on("-I", "--include PATH",
		  "specify $LOAD_PATH (may be used more than once)") { |path|
	    options[:include] = path.split(":")
	  }

	  opts.on("-r", "--require LIBRARY",
		  "require the library, before executing your script") { |library|
	    options[:require] = library
	  }

	  opts.separator ""
	  opts.separator "Rack options:"
	  opts.on("-s", "--server SERVER", "serve using SERVER (webrick/mongrel)") { |s|
	    options[:server] = s
	  }

	  opts.on("-o", "--host HOST", "listen on HOST (default: 0.0.0.0)") { |host|
	    options[:Host] = host
	  }

	  opts.on("-p", "--port PORT", "use PORT (default: 9292)") { |port|
	    options[:Port] = port
	  }

	  opts.on("-O", "--option NAME[=VALUE]", "pass VALUE to the server as option NAME. If no VALUE, sets it to true. Run '#{$0} -s SERVER -h' to get a list of options for SERVER") { |name|
	    name, value = name.split('=', 2)
	    value = true if value.nil?
	    options[name.to_sym] = value
	  }

	  opts.on("-E", "--env ENVIRONMENT", "use ENVIRONMENT for defaults (default: development)") { |e|
	    options[:environment] = e
	  }

	  opts.on("-D", "--daemonize", "run daemonized in the background") { |d|
	    options[:daemonize] = d ? true : false
	  }

	  opts.on("-P", "--pid FILE", "file to store PID (default: rack.pid)") { |f|
	    options[:pid] = ::File.expand_path(f)
	  }

	  opts.separator ""
	  opts.separator "Common options:"

	  opts.on_tail("-h", "-?", "--help", "Show this message") do
	    puts opts
	    puts handler_opts(options)

	    exit
	  end


	  opts.on_tail("--version", "Show version") do
	    puts "Rack #{Rack.version} (Release: #{Rack.release})"
	    exit
	  end
	end

	begin
	  opt_parser.parse! args
	rescue OptionParser::InvalidOption => e
	  warn e.message
	  abort opt_parser.to_s
	end

	options
      end
    end
  end
end


Pry.config.hooks.add_hook(:before_session, :add_load_path) do
  %w(lib spec test)
	.map { |dir| File.expand_path("../#{dir}", __FILE__) }
	.each { |lib| $LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib) }
end

# vim: syn=ruby :

require 'rake'

desc 'Run specs'
task :spec do
  Dir['spec/jobget/*.rb'].each do |rb|
    ruby rb
  end
end

desc 'check and install missing dependencies of Any2Text'
task :check do
  require 'vendor/any2text'

  missing = []

  Any2Text::DEPENDENCIES.each do |bin|
    sh('which', bin) do |good, status|
      missing << bin unless good
    end
  end

  puts

  if missing.empty?
    puts "All dependencies found, all features of Any2Text available"
  else
    puts "Your system is missing following dependencies:"
    puts missing.join(' ')
    puts "I'm now attempting to install them"
    sh 'sudo', 'pacman', '-S', *missing
  end
end

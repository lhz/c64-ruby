require 'c64'
require 'rake'

$:.unshift('./lib')

# Extend task class
class Rake::Task

  attr_accessor :input, :output

  def debug(message)
    puts "[Rake::Task: #{name}] #{message}" if Rake.verbose == true
  end

  def on_change(io = nil, &block)
    if io && io.respond_to?(:keys) && io.keys.size == 1
      self.input  = io.keys.first
      self.output = io.values.first
    end
    # Depend on input and task file
    deps = Array(input) + [caller[0].split(':').first]
    if dependencies_changed?(deps, Array(output))
      debug "Performing task."
      block.call(self)
    end
  end

  def dependencies_changed?(sources = prerequisites, targets = [name])
    sources = sources.dup.select {|f| File.exists?(f) }
    targets = targets.dup.select {|f| File.exists?(f) }
    if sources.empty?
      debug "Source files do not exist."
      return true
    end
    if targets.empty?
      debug "Target files do not exist."
      return true
    end
    mtime_newest_source = sources.map {|f| [f, File.mtime(f)] }.max_by {|s| s[1]}
    mtime_oldest_target = targets.map {|f| [f, File.mtime(f)] }.min_by {|t| t[1]}
    if mtime_newest_source[1] > mtime_oldest_target[1]
      debug "Source #{mtime_newest_source[0]} changed."
      return true
    end
    false
  end
end

# Guess project name from name of current directory
if !(defined? PROJECT)
  PROJECT = File.basename(Dir.pwd)
end

LINKABLE = ENV['LINKABLE']

CA65_OPTS = ["-U -g -l #{PROJECT}.lst"]
CA65_OPTS << '-D LINKABLE=1' if LINKABLE

# Locate directory containing shared code
if !(defined? SHARED)
  path = Dir.pwd
  while path != '/'
    if File.exists?(File.join(path, 'shared/linker.cfg'))
      SHARED = File.join(path, 'shared')
      break
    end
    path = File.expand_path(File.join(path, '..'))
  end
  defined? SHARED or
    raise "Unable to locate directory containing shared code!"
  CA65_OPTS << "-I #{SHARED}"
end

LINKER_CFG =
  if File.exists?('linker.cfg')
    'linker.cfg'
  else 
    File.join(SHARED, 'linker.cfg')
  end

UNCOMPILED_PRG = "#{PROJECT}-uncompiled.prg"
COMPILED_PRG = "#{PROJECT}.prg"
MERGED_PRG = "#{PROJECT}-merged.prg"

STARTUP = (LINKABLE ? 'startup-nobasic' : 'startup')

# Require source files inside lib
Dir.glob('lib/**/*.rb').each {|file| require File.expand_path(file) }

# Load .rake files inside lib/tasks
Dir.glob('lib/tasks/**/*.rake').each {|file| load File.expand_path(file) }

# Assemble startup files
rule "#{STARTUP}.o" => [File.join(SHARED, "#{STARTUP}.s")] do |t|
  sh "ca65 #{CA65_OPTS.join(' ')} -o #{t.name} #{t.source}"
end

# Assemble source files into object files
rule '.o' => ['.s'] do |t|
  sh "ca65 #{CA65_OPTS.join(' ')} -o #{t.name} #{t.source}"
end

# Subtasks for generation of binaries through scripts
desc "Generate binaries through subtasks."
task :binaries

# Link object files into uncompiled program
desc "Link object files into uncompiled program, binaries not included."
task :program_uncompiled => ["#{STARTUP}.o", "#{PROJECT}.o"] do |t|
  labels_file = '/tmp/x64-labels.lab'
  if t.dependencies_changed?(t.prerequisites, [UNCOMPILED_PRG])
    sh "ld65 -o #{UNCOMPILED_PRG} -m linker.map -C #{LINKER_CFG} " <<
      "-Ln #{labels_file} #{t.prerequisites.join ' '}"
  end
end

# Compile executable and binaries
desc "Created compiled program, including binaries."
task :program_compiled => [:program_uncompiled, :binaries] do |t|
  binaries = Rake::Task[:binaries].prerequisites.map {|tn|
    Array(Rake::Task[tn].output)
  }.flatten.compact
  if t.dependencies_changed?([UNCOMPILED_PRG] + binaries, [COMPILED_PRG])
    sh "exomizer sfx sys -q -n -m1024 -p1 -o #{COMPILED_PRG}" <<
      " #{UNCOMPILED_PRG} #{binaries.join(' ')}"
  end
end

# Join executable and binaries into a single program
desc "Join executable and binaries"
task :program_merged => [:program_uncompiled, :binaries] do |t|
  binaries = Rake::Task[:binaries].prerequisites.map {|tn|
    Array(Rake::Task[tn].output)
  }.flatten.compact
  if t.dependencies_changed?([UNCOMPILED_PRG] + binaries, [MERGED_PRG])
    sh "prgmerge #{UNCOMPILED_PRG} #{binaries.join(' ')} > #{MERGED_PRG}"
  end
end

# Run program in emulator
desc "Run compiled program in emulator."
task :run => :program_merged do |t|
  sh "x64 -autostartprgmode 1 #{ENV['VICEOPTS']} #{MERGED_PRG} >/tmp/x64.log 2>&1 || exit 0"
end

# Clean up
desc "Remove generated files."
task :clean do
  sh "rm -f *.o *.prg *.d64 *.map *.lst *.vcl *.bin"
end

# Set default task - run program
#if File.exists?("#{PROJECT}.s")
#  task :default => :run
#end

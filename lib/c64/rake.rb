require 'c64'
require 'rake'

$:.unshift('./lib')

# Extend task class
class Rake::Task

  attr_accessor :input, :output

  def plist
    prerequisites.join ' '
  end

  def shell(command)
    puts "#{command}" if Rake.verbose
    output = %x(#{command})
    $?.success? or
      raise "Shell command failed: #{$!}\nCommand: #{command}\nOutput: #{output}"
    output
  end

  def on_change(&block)
    # Depend on input and task file
    deps = input + [caller[0].split(':').first]
    if dependencies_changed?(deps, output)
      puts "[Performing task '#{name}']" if Rake.verbose
      block.call(self)
    end
  end

  def dependencies_changed?(sources = prerequisites, targets = [name])
    sources = sources.dup.select {|f| File.exists?(f) }
    targets = targets.dup.select {|f| File.exists?(f) }
    if sources.empty? || targets.empty?
      true
    else
      mtime_newest_source = sources.map {|f| File.mtime(f) }.max
      mtime_oldest_target = targets.map {|f| File.mtime(f) }.min
      mtime_newest_source > mtime_oldest_target
    end
  end
end

# Guess project name from name of current directory
if !(defined? PROJECT)
  PROJECT = File.basename(Dir.pwd)
end

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
end

UNCOMPILED_PRG = "#{PROJECT}-uncompiled.prg"
COMPILED_PRG = "#{PROJECT}.prg"

# Load .rake files inside lib/tasks
Dir.glob('lib/tasks/**/*.rake').each {|rake_file| load(rake_file) }

# Assemble startup file
rule 'startup.o' => [File.join(SHARED, 'startup.s')] do |t|
  sh "ca65 -U -g -l -o #{t.name} #{t.source}"
end

# Assemble source files into object files
rule '.o' => ['.s'] do |t|
  sh "ca65 -U -g -l -o #{t.name} #{t.source}"
end

# Subtasks for generation of binaries through scripts
desc "Generate binaries through subtasks."
task :binaries

# Link object files into uncompiled program
desc "Link object files into uncompiled program, binaries not included."
task :program_uncompiled => ["startup.o", "#{PROJECT}.o"] do |t|
  config_file = File.join(SHARED, 'linker.cfg')
  labels_file = '/tmp/x64-labels.lab'
  if t.dependencies_changed?(t.prerequisites, [UNCOMPILED_PRG])
    sh "ld65 -m linker.map -C #{config_file} -Ln #{labels_file}" <<
      " -o #{UNCOMPILED_PRG} #{t.plist}"
  end
end

# Compile executable and binaries
desc "Created compiled program, including binaries."
task :program_compiled => [:program_uncompiled, :binaries] do |t|
  binaries = Rake::Task[:binaries].prerequisites.map {|tn|
    Rake::Task[tn].output
  }.flatten.compact
  if t.dependencies_changed?([UNCOMPILED_PRG] + binaries, [COMPILED_PRG])
    sh "exomizer sfx sys -q -n -m1024 -p1 -o #{COMPILED_PRG}" <<
      " #{UNCOMPILED_PRG} #{binaries.join(' ')}"
  end
end

# Run program in emulator
desc "Run compiled program in emulator."
task :run => :program_compiled do |t|
  sh "x64 #{COMPILED_PRG} >/dev/null"
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

#!/usr/bin/env ruby
require 'xcodeproj'

PROJECT_PATH = '/Users/loop/project/PetFriendlyWatch/PetFriendlyWatch.xcodeproj'

project = Xcodeproj::Project.open(PROJECT_PATH)
t = project.targets.first

# Remove any existing CopyAndPreserveArchs phases
t.build_phases.each do |p|
  if p.respond_to?(:name) && p.name.to_s == 'CopyAndPreserveArchs'
    t.build_phases.delete(p)
    puts "Removed existing CopyAndPreserveArchs"
  end
end

# Add a shell script CopyAndPreserveArchs phase (what Xcode GUI actually creates)
script_phase = project.new(Xcodeproj::Project::Object::PBXShellScriptBuildPhase)
script_phase.name = 'CopyAndPreserveArchs'
script_phase.shell_script = <<~'SCRIPT'
  # CopyAndPreserveArchs
  # Placeholder script to prevent the build system from adding an implicit phase
  # that conflicts with the linker output.
  # This is required for watchOS 2 app targets on Xcode 16+.
  if [ "$ACTION" = "install" ]; then
    echo "CopyAndPreserveArchs: preserving architectures..."
  fi
SCRIPT
script_phase.shell_path = '/bin/sh'
script_phase.input_paths = []
script_phase.output_paths = []
script_phase.build_action_mask = '2147483647'
script_phase.show_env_vars_in_log = '0'

# Insert after resources phase
resources_idx = t.build_phases.index { |p| p.is_a?(Xcodeproj::Project::Object::PBXResourcesBuildPhase) }
t.build_phases.insert(resources_idx + 1, script_phase) if resources_idx

# Set back to multi-arch for proper watchOS build
t.build_configurations.each do |c|
  bs = c.build_settings
  bs['ARCHS'] = 'arm64'
  bs['ONLY_ACTIVE_ARCH'] = 'YES'
  bs.delete('VALID_ARCHS')
  bs.delete('EXCLUDED_ARCHS')
end

project.save
puts "✅ Added Shell Script CopyAndPreserveArchs phase"

# Verify
t.build_phases.each_with_index do |p, i|
  cls = p.class.name.split('::').last
  name = p.respond_to?(:name) ? (p.name || '') : ''
  puts "  #{i}: #{cls} #{name}"
end

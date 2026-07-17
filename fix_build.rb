#!/usr/bin/env ruby
require 'xcodeproj'

PROJECT_PATH = '/Users/loop/project/PetFriendlyWatch/PetFriendlyWatch.xcodeproj'

project = Xcodeproj::Project.open(PROJECT_PATH)
t = project.targets.first

# Remove CopyAndPreserveArchs phase
t.build_phases.each do |p|
  if p.respond_to?(:name) && p.name == 'CopyAndPreserveArchs'
    t.build_phases.delete(p)
    puts "Removed CopyAndPreserveArchs phase"
  end
end

# Set single architecture to avoid universal binary issues
t.build_configurations.each do |c|
  bs = c.build_settings
  bs['ARCHS'] = 'arm64'
  bs['ONLY_ACTIVE_ARCH'] = 'YES'
  bs['VALID_ARCHS'] = 'arm64'
  bs['EXCLUDED_ARCHS'] = 'arm64_32 x86_64'
end

project.save
puts "✅ Fixed build settings (single arch)"
puts "  ARCHS=arm64, ONLY_ACTIVE_ARCH=YES"

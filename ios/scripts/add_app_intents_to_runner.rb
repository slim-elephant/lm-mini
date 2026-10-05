#!/usr/bin/env ruby
# add_app_intents_to_runner.rb
#
# Adds ios/Runner/LMMiniAppIntents.swift to the Runner target's Sources
# build phase so the App Intents (Phase B of the Shortcuts integration)
# get compiled and registered with the system. Idempotent.

require 'xcodeproj'

PROJECT_PATH = File.expand_path('../Runner.xcodeproj', __dir__)
project = Xcodeproj::Project.open(PROJECT_PATH)

runner = project.targets.find { |t| t.name == 'Runner' }
abort('Runner target not found') unless runner

# Find the Runner group (the on-disk folder containing AppDelegate.swift etc.).
runner_group = project.main_group['Runner']
abort('Runner group not found') unless runner_group

file_name = 'LMMiniAppIntents.swift'
file_path = "Runner/#{file_name}"

# Idempotent: skip if already present in the project file or build phase.
existing_ref = runner_group.files.find { |f| f.path == file_name } ||
               project.files.find { |f| f.real_path.to_s.end_with?(file_path) }

if existing_ref.nil?
  existing_ref = runner_group.new_file(file_name)
  puts "  + added file reference: #{file_path}"
else
  puts "  file reference already present: #{file_path}"
end

already_in_sources = runner.source_build_phase.files.any? do |bf|
  bf.file_ref == existing_ref
end
unless already_in_sources
  runner.source_build_phase.add_file_reference(existing_ref)
  puts "  + added to Sources build phase"
end

project.save
puts "✅ LMMiniAppIntents.swift wired into Runner target."

#!/usr/bin/env ruby
# Idempotently adds an Xcode Run Script phase that embeds
# Runner/Resources/runtime into the .app for Mac App Store builds.
require 'xcodeproj'

PROJECT_PATH = File.expand_path('../Runner.xcodeproj', __dir__)
PHASE_NAME = 'Embed Desktop Runtime'

project = Xcodeproj::Project.open(PROJECT_PATH)
runner = project.targets.find { |t| t.name == 'Runner' }
abort('Runner target not found') unless runner

existing = runner.shell_script_build_phases.find { |p| p.name == PHASE_NAME }
if existing
  puts "  #{PHASE_NAME} already present"
else
  phase = project.new(Xcodeproj::Project::Object::PBXShellScriptBuildPhase)
  phase.name = PHASE_NAME
  phase.shell_path = '/bin/sh'
  phase.shell_script = "\"${SRCROOT}/scripts/embed_desktop_runtime.sh\"\n"
  phase.run_only_for_deployment_postprocessing = '0'
  # After Resources / before Flutter embed is fine — append near end.
  runner.build_phases << phase
  puts "  added build phase: #{PHASE_NAME}"
end

project.save
puts 'Done.'

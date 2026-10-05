#!/usr/bin/env ruby
# add_mlx_to_runner.rb
#
# Re-attaches MLX Swift Package dependencies to the macOS Runner target and
# ensures MLXBridge.swift is in the compile sources. Idempotent.
#
#   mlx-swift          == 0.25.6
#   mlx-swift-examples == 2.25.9
#
# Products:
#   mlx-swift          → MLX, MLXNN, MLXRandom, MLXFast
#   mlx-swift-examples → MLXLLM, MLXLMCommon

require 'xcodeproj'

PROJECT_PATH = File.expand_path('../Runner.xcodeproj', __dir__)
BRIDGE_PATH = File.expand_path('../Runner/MLXBridge.swift', __dir__)

project = Xcodeproj::Project.open(PROJECT_PATH)

runner = project.targets.find { |t| t.name == 'Runner' }
abort('Runner target not found') unless runner

runner_group = project.main_group['Runner'] || project.main_group

def find_or_create_pkg_ref(project, url, version)
  existing = project.root_object.package_references.find do |p|
    p.respond_to?(:repositoryURL) && p.repositoryURL == url
  end
  if existing
    existing.requirement = { 'kind' => 'exactVersion', 'version' => version }
    puts "  package ref already present: #{url} (pin updated to #{version})"
    return existing
  end
  ref = project.new(Xcodeproj::Project::Object::XCRemoteSwiftPackageReference)
  ref.repositoryURL = url
  ref.requirement = { 'kind' => 'exactVersion', 'version' => version }
  project.root_object.package_references << ref
  puts "  added package ref: #{url} @ #{version}"
  ref
end

mlx_swift_ref = find_or_create_pkg_ref(
  project,
  'https://github.com/ml-explore/mlx-swift',
  '0.25.6'
)
mlx_examples_ref = find_or_create_pkg_ref(
  project,
  'https://github.com/ml-explore/mlx-swift-examples',
  '2.25.9'
)

def attach_product(project, target, package_ref, product_name)
  dep = target.package_product_dependencies.find { |d| d.product_name == product_name }
  unless dep
    dep = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
    dep.package = package_ref
    dep.product_name = product_name
    target.package_product_dependencies << dep
    puts "  attached package product: #{product_name}"
  else
    dep.package = package_ref
    puts "  product already attached: #{product_name}"
  end

  already_in_frameworks = target.frameworks_build_phase.files.any? do |bf|
    bf.product_ref == dep
  end
  unless already_in_frameworks
    bf = project.new(Xcodeproj::Project::Object::PBXBuildFile)
    bf.product_ref = dep
    target.frameworks_build_phase.files << bf
    puts "    + linked into Frameworks build phase"
  end
end

%w[MLX MLXNN MLXRandom MLXFast].each do |name|
  attach_product(project, runner, mlx_swift_ref, name)
end
%w[MLXLLM MLXLMCommon].each do |name|
  attach_product(project, runner, mlx_examples_ref, name)
end

# Ensure MLXBridge.swift is in the Runner group and Sources build phase.
bridge_ref = runner_group.files.find { |f| f.path == 'MLXBridge.swift' }
unless bridge_ref
  bridge_ref = runner_group.new_file('MLXBridge.swift')
  puts '  added MLXBridge.swift file reference'
end
unless runner.source_build_phase.files_references.include?(bridge_ref)
  runner.source_build_phase.add_file_reference(bridge_ref)
  puts '  added MLXBridge.swift to Sources build phase'
end

project.save
puts '✅ MLX packages attached to macOS Runner. Next: flutter build macos --release'

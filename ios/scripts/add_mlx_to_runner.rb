#!/usr/bin/env ruby
# add_mlx_to_runner.rb
#
# Re-attaches MLX Swift Package dependencies to the Runner target.
# Pins to versions that still support iOS 16.0 (mlx-swift main now
# requires iOS 17, which our 16.0 deployment target cannot accept):
#
#   mlx-swift              == 0.25.6  (last iOS 16 compatible release)
#   mlx-swift-examples     == 2.25.9  (depends on mlx-swift 0.25.x, iOS 16)
#
# Products attached:
#   from mlx-swift           → MLX, MLXNN, MLXRandom, MLXFast
#   from mlx-swift-examples  → MLXLLM, MLXLMCommon
#
# Idempotent — safe to re-run after `flutter clean` / `pod install` if
# anything strips them. Pair with ios/Runner/MLXBridge.swift which is
# guarded by `#if canImport(MLXLLM)` so it stays compilable even when
# this script hasn't been run yet.

require 'xcodeproj'

PROJECT_PATH = File.expand_path('../Runner.xcodeproj', __dir__)
project = Xcodeproj::Project.open(PROJECT_PATH)

runner = project.targets.find { |t| t.name == 'Runner' }
abort('Runner target not found') unless runner

def find_or_create_pkg_ref(project, url, version)
  existing = project.root_object.package_references.find do |p|
    p.respond_to?(:repositoryURL) && p.repositoryURL == url
  end
  if existing
    # Make sure the pin is current.
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
  # Reuse existing dep if any.
  dep = target.package_product_dependencies.find { |d| d.product_name == product_name }
  unless dep
    dep = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
    dep.package = package_ref
    dep.product_name = product_name
    target.package_product_dependencies << dep
    puts "  attached package product: #{product_name}"
  else
    # Re-point to the requested package ref in case the ref got recreated.
    dep.package = package_ref
    puts "  product already attached: #{product_name}"
  end

  # Make sure the Frameworks build phase has a build file pointing at this
  # product. Without this the linker never sees the symbols.
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

# mlx-swift core products
%w[MLX MLXNN MLXRandom MLXFast].each do |name|
  attach_product(project, runner, mlx_swift_ref, name)
end
# mlx-swift-examples products (the actual LLM runtime)
%w[MLXLLM MLXLMCommon].each do |name|
  attach_product(project, runner, mlx_examples_ref, name)
end

project.save
puts "✅ MLX packages attached to Runner. Next: `cd ios && rm -rf Pods && pod install`."

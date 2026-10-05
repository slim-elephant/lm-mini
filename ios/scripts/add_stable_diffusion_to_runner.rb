#!/usr/bin/env ruby
# add_stable_diffusion_to_runner.rb
#
# Attaches the local CoreMLStableDiffusion package to the Runner target:
#
#   ios/Packages/CoreMLStableDiffusion  (vendored apple/ml-stable-diffusion 1.1.1)
#   product: CoreMLStableDiffusion
#
# Uses a renamed local package so it can coexist with mlx-swift-examples,
# which also declares a target named StableDiffusion.
#
# Idempotent — safe to re-run after `flutter clean` / pbxproj surgery.
# Pair with ios/Runner/OnDeviceSdBridge.swift which is guarded by
# `#if canImport(CoreMLStableDiffusion)` so the project still compiles when
# this script hasn't been run yet.

require 'xcodeproj'

PROJECT_PATH = File.expand_path('../Runner.xcodeproj', __dir__)
project = Xcodeproj::Project.open(PROJECT_PATH)

runner = project.targets.find { |t| t.name == 'Runner' }
abort('Runner target not found') unless runner

REMOTE_SD_URL = 'https://github.com/apple/ml-stable-diffusion'
OLD_PRODUCT = 'StableDiffusion'
LOCAL_RELATIVE_PATH = 'Packages/CoreMLStableDiffusion'
LOCAL_PRODUCT = 'CoreMLStableDiffusion'

def remove_remote_ml_stable_diffusion!(project, target, url, old_product)
  # Drop product deps named StableDiffusion (and their Frameworks entries).
  target.package_product_dependencies.select { |d| d.product_name == old_product }.each do |dep|
    target.frameworks_build_phase.files.select { |bf| bf.product_ref == dep }.each do |bf|
      bf.remove_from_project
      puts "  removed Frameworks entry for #{old_product}"
    end
    dep.remove_from_project
    puts "  removed package product dependency: #{old_product}"
  end

  # Drop remote package refs to apple/ml-stable-diffusion.
  project.root_object.package_references.select do |p|
    p.respond_to?(:repositoryURL) && p.repositoryURL == url
  end.each do |ref|
    # Orphaned product deps that still pointed at this ref.
    project.targets.each do |t|
      t.package_product_dependencies.select { |d| d.package == ref }.each do |dep|
        t.frameworks_build_phase.files.select { |bf| bf.product_ref == dep }.each(&:remove_from_project)
        dep.remove_from_project
        puts "  removed orphaned product dep pointing at remote #{url}"
      end
    end
    ref.remove_from_project
    puts "  removed remote package ref: #{url}"
  end
end

def find_or_create_local_pkg_ref(project, relative_path)
  # Drop stale local refs that look like CoreMLStableDiffusion but wrong path.
  project.root_object.package_references.select do |p|
    p.is_a?(Xcodeproj::Project::Object::XCLocalSwiftPackageReference) &&
      [p.relative_path, p.path].compact.any? { |rp| rp.to_s.include?("CoreMLStableDiffusion") } &&
      p.relative_path != relative_path && p.path != relative_path
  end.each do |stale|
    project.targets.each do |t|
      t.package_product_dependencies.select { |d| d.package == stale }.each do |dep|
        t.frameworks_build_phase.files.select { |bf| bf.product_ref == dep }.each(&:remove_from_project)
        # Keep the product dep object; we'll re-point it below if name matches.
        dep.package = nil
        puts "  detached product dep from stale local ref #{stale.relative_path || stale.path}"
      end
    end
    stale.remove_from_project
    puts "  removed stale local package ref: #{stale.relative_path || stale.path}"
  end

  existing = project.root_object.package_references.find do |p|
    p.is_a?(Xcodeproj::Project::Object::XCLocalSwiftPackageReference) &&
      (p.relative_path == relative_path || p.path == relative_path)
  end
  if existing
    existing.relative_path = relative_path
    puts "  local package ref already present: #{relative_path}"
    return existing
  end
  ref = project.new(Xcodeproj::Project::Object::XCLocalSwiftPackageReference)
  ref.relative_path = relative_path
  project.root_object.package_references << ref
  puts "  added local package ref: #{relative_path}"
  ref
end

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

def ensure_swift_file(project, target, filename)
  runner_group = project.main_group.find_subpath('Runner', true)
  file_ref = runner_group.files.find { |f| f.path == filename }
  unless file_ref
    file_ref = runner_group.new_reference(filename)
    puts "  added file ref: #{filename}"
  end

  already = target.source_build_phase.files.any? do |bf|
    bf.file_ref && bf.file_ref.path == filename
  end
  unless already
    target.source_build_phase.add_file_reference(file_ref)
    puts "  + #{filename} in Compile Sources"
  end
end

puts 'Migrating Runner to local CoreMLStableDiffusion…'
remove_remote_ml_stable_diffusion!(project, runner, REMOTE_SD_URL, OLD_PRODUCT)
local_ref = find_or_create_local_pkg_ref(project, LOCAL_RELATIVE_PATH)
attach_product(project, runner, local_ref, LOCAL_PRODUCT)
ensure_swift_file(project, runner, 'OnDeviceSdBridge.swift')

project.save
puts '✅ CoreMLStableDiffusion local package attached to Runner. Next: open Xcode once to resolve packages, or `cd ios && xcodebuild -resolvePackageDependencies`.'

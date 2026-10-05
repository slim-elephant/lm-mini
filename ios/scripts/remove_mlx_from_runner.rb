#!/usr/bin/env ruby
# Removes MLX Swift Package dependencies from the Runner target so the app can
# archive with iOS 15.5 deployment target. MLX-swift now requires iOS 17 on its
# `main` branch, which is incompatible with a 15.5 minimum target.
#
# The MLXBridge.swift file is preserved and continues to compile — its #if
# canImport(MLXLLM) guards make every method return a descriptive Flutter
# error when MLX is absent (which is exactly what we want for iOS 15.5/16).
#
# To re-enable MLX on iOS 17+ later, create a separate dynamic framework
# target (e.g. "MLXKit") with IPHONEOS_DEPLOYMENT_TARGET=17.0, move
# MLXBridge.swift into it, attach the MLX SPM products there, and have Runner
# weakly embed the framework. See ios/Runner/MLXBridge.swift header comment.

require 'xcodeproj'

PROJECT_PATH = File.expand_path('../Runner.xcodeproj', __dir__)
project = Xcodeproj::Project.open(PROJECT_PATH)

runner = project.targets.find { |t| t.name == 'Runner' }
abort('Runner target not found') unless runner

mlx_product_names = %w[MLX MLXFast MLXNN MLXRandom MLXMNIST StableDiffusion MLXOptimizers]

removed_frameworks = 0
runner.frameworks_build_phase.files.dup.each do |bf|
  product = bf.product_ref
  next unless product
  if mlx_product_names.include?(product.product_name)
    runner.frameworks_build_phase.remove_build_file(bf)
    removed_frameworks += 1
    puts "  Removed framework build file: #{product.product_name}"
  end
end

# Detach package product dependencies from the target
removed_deps = 0
runner.package_product_dependencies.dup.each do |dep|
  if mlx_product_names.include?(dep.product_name)
    runner.package_product_dependencies.delete(dep)
    removed_deps += 1
    puts "  Detached package product: #{dep.product_name}"
  end
end

# Remove the XCRemoteSwiftPackageReference entries from the project so SPM
# doesn't try to resolve mlx-swift / mlx-swift-examples on every build.
mlx_repo_urls = %w[
  https://github.com/ml-explore/mlx-swift
  https://github.com/ml-explore/mlx-swift-examples
]
removed_pkgs = 0
project.root_object.package_references.dup.each do |pkg|
  url = pkg.respond_to?(:repositoryURL) ? pkg.repositoryURL : nil
  if url && mlx_repo_urls.include?(url)
    project.root_object.package_references.delete(pkg)
    removed_pkgs += 1
    puts "  Removed package reference: #{url}"
  end
end

# Also drop orphaned XCSwiftPackageProductDependency objects whose product name
# matches an MLX product (no target references them now).
removed_orphan = 0
project.objects.dup.each do |obj|
  next unless obj.isa == 'XCSwiftPackageProductDependency'
  if mlx_product_names.include?(obj.product_name)
    obj.remove_from_project
    removed_orphan += 1
  end
end

project.save

puts "✅ MLX cleanup done: #{removed_frameworks} framework build files, " \
     "#{removed_deps} package dependencies, #{removed_pkgs} package references, " \
     "#{removed_orphan} orphan product objects removed."

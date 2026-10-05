# CoreMLStableDiffusion

Local Swift package that vendors [apple/ml-stable-diffusion](https://github.com/apple/ml-stable-diffusion) (1.1.1) under a **renamed** module/product: `CoreMLStableDiffusion`.

## Why it exists

The Runner app also depends on `mlx-swift-examples`, which declares a target named `StableDiffusion`. SPM forbids two packages in the same dependency graph from declaring the same target name. Pulling Apple’s remote package (`StableDiffusion`) alongside MLX therefore fails with:

```text
multiple packages ('ml-stable-diffusion', 'mlx-swift-examples') declare targets with a conflicting name: 'StableDiffusion'
```

Vendoring Apple’s sources here with a distinct package/product/target name avoids that clash while keeping the same APIs (`StableDiffusionPipeline`, `PipelineConfiguration`, etc.).

## Wiring

Attach this package to the Runner target with:

```bash
ruby ios/scripts/add_stable_diffusion_to_runner.rb
```

That script adds an `XCLocalSwiftPackageReference` to `Packages/CoreMLStableDiffusion` (relative to `ios/`, where `Runner.xcodeproj` lives) and links the `CoreMLStableDiffusion` product.

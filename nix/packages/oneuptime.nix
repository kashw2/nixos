{ ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages = {
        oneuptime-app = pkgs.callPackage (
          {
            lib,
            buildNpmPackage,
            fetchFromGitHub,
            fetchNpmDeps,
            makeWrapper,
            nodejs_26,
            npm-lockfile-fix,
          }:

          let
            # Common and the six frontends are separate npm projects that depend on each other by path, so each needs its own deps
            workspaces = {
              "packages/Common" = "sha256-UVQVgdZLFaXelE9/vwL0RiZ8INI6U0EguyBcbCEVhww=";
              "packages/App/FeatureSet/Accounts" = "sha256-789vqpdCw908bEC/Cp2OFH988GV4+vw248MroHeH/Tg=";
              "packages/App/FeatureSet/AdminDashboard" = "sha256-022BA2twedjZdC26q7TWAhUMUIJsv1kMp6qeaDW8Hwg=";
              "packages/App/FeatureSet/BrowserRecorder" = "sha256-gfTNduWJZaOE5sLrNc+6Y9hnHbtwD6GzR0QS8zfjJ04=";
              "packages/App/FeatureSet/Dashboard" = "sha256-vqeBJ7rz7tLw7FVLa5ZSPguC1bQ/L46khTi/oat+h68=";
              "packages/App/FeatureSet/PublicDashboard" = "sha256-EROXrJ4WXK2qv7XZoBbQuyXSb2SX439lHxUarcF1ipg=";
              "packages/App/FeatureSet/StatusPage" = "sha256-yGan/f3yPYe9PFNFzfRaP55nbQs+YqX4F87oeVyQa28=";
            };
          in
          buildNpmPackage (finalAttrs: {
            pname = "oneuptime-app";
            version = "14.0.6";

            __structuredAttrs = true;

            src = fetchFromGitHub {
              owner = "OneUptime";
              repo = "oneuptime";
              tag = finalAttrs.version;
              hash = "sha256-lAXHLVIUA4XstFSZ6h8jN8bpucrDKzHU+dVMJTDUnOQ=";
            };

            sourceRoot = "${finalAttrs.src.name}/packages/App";

            nodejs = nodejs_26;

            npmDepsHash = "sha256-KQRKbKm8UM0qlcwP4HfvTCCFPz5Rb5SH9eeBV8xbvuY=";

            nativeBuildInputs = [ makeWrapper ];

            # unpackPhase only makes sourceRoot writable, and Common sits outside it.
            postPatch = ''
              chmod -R u+w ..
            '';

            preBuild = lib.concatLines (
              lib.mapAttrsToList (
                dir: hash:
                let
                  deps = fetchNpmDeps {
                    name = "oneuptime-${lib.toLower (baseNameOf dir)}-npm-deps-${finalAttrs.version}";
                    src = "${finalAttrs.src}/${dir}";
                    # Upstream ships some of these lockfiles without `resolved`/`integrity` on a chunk of their entries, which cannot be fetched
                    nativeBuildInputs = [ npm-lockfile-fix ];
                    preBuild = "npm-lockfile-fix package-lock.json";
                    inherit hash;
                  };
                in
                ''
                  (
                    cd ../../${dir}
                    # npmConfigHook requires both lockfiles to be identical, so take the
                    # repaired one back out of the fetched deps.
                    cp ${deps}/package-lock.json package-lock.json
                    export npmDeps=${deps}
                    npmConfigHook
                  )
                ''
              ) workspaces
            );

            npmBuildScript = "build-frontends:prod";

            # The Dashboard service worker bakes both into its cache key at build time,
            # falling back to md5(Date.now()), which would make $out unreproducible.
            env = {
              GIT_SHA = finalAttrs.version;
              APP_VERSION = finalAttrs.version;
            };

            postBuild = ''
              # The same generator stamps a wall-clock timestamp nothing reads.
              sed -i 's/^ \* Generated at: .*/ * Generated at: (reproducible build)/' \
                FeatureSet/Dashboard/public/sw.js
            '';

            installPhase = ''
              runHook preInstall

              install -d $out/lib/oneuptime
              cp -a ../Common $out/lib/oneuptime/Common
              cp -a . $out/lib/oneuptime/App

              # Some FeatureSets and Common resolve views, assets and docs against the Docker image's WORKDIR rather than their own location.
              find $out/lib/oneuptime -type f \( -name '*.ts' -o -name '*.ejs' \) \
                -not -path '*/node_modules/*' -not -path '*/Tests/*' \
                -exec sed -i \
                  "s#/usr/src/app#$out/lib/oneuptime/App#g; s#/usr/src/Common#$out/lib/oneuptime/Common#g" {} +

              makeWrapper ${lib.getExe nodejs_26} $out/bin/oneuptime-app \
                --chdir $out/lib/oneuptime/App \
                --add-flags "--no-node-snapshot --require ts-node/register $out/lib/oneuptime/App/Index.ts" \
                --set TS_NODE_TRANSPILE_ONLY 1 \
                --set APP_VERSION ${finalAttrs.version}

              makeWrapper ${lib.getExe nodejs_26} $out/bin/oneuptime-app-migrate \
                --chdir $out/lib/oneuptime/App \
                --add-flags "--no-node-snapshot --require ts-node/register $out/lib/oneuptime/App/Migrate.ts" \
                --set TS_NODE_TRANSPILE_ONLY 1 \
                --set APP_VERSION ${finalAttrs.version}

              runHook postInstall
            '';

            meta = {
              mainProgram = "oneuptime-app";
              platforms = lib.platforms.linux;
            };
          })
        ) { };

        oneuptime-cli = pkgs.callPackage (
          {
            lib,
            buildNpmPackage,
            fetchFromGitHub,
            fetchNpmDeps,
            nix-update-script,
            nodejs_26,
            versionCheckHook,
          }:

          let
            version = "14.0.6";

            src = fetchFromGitHub {
              owner = "OneUptime";
              repo = "oneuptime";
              tag = version;
              hash = "sha256-lAXHLVIUA4XstFSZ6h8jN8bpucrDKzHU+dVMJTDUnOQ=";
            };

            commonNpmDeps = fetchNpmDeps {
              name = "oneuptime-common-npm-deps-${version}";
              src = "${src}/packages/Common";
              hash = "sha256-zOWPBxJazRMyMa8A58CPQVQgAgicvqKqDMI5UruPH+w=";
            };
          in
          buildNpmPackage {
            pname = "oneuptime-cli";
            inherit version src;

            __structuredAttrs = true;

            sourceRoot = "${src.name}/packages/CLI";

            nodejs = nodejs_26;

            npmDepsHash = "sha256-nK3KZZvJ6R5t/8Q3llBf5Td7L2JOjcwh8pCxFyGVL20=";

            preBuild = ''
              chmod -R u+w ../Common

              (
                export npmRoot=../Common
                export npmDeps=${commonNpmDeps}
                npmFlags=""
                npmFlagsArray=()

                npmConfigHook
              )
            '';

            nativeBuildInputs = [
              versionCheckHook
            ];

            postInstall = ''
              cp -a ../Common $out/lib/node_modules/@oneuptime/Common
            '';

            versionCheckProgramArg = "version";

            passthru.updateScript = nix-update-script { };

            meta = {
              mainProgram = "oneuptime";
              platforms = lib.platforms.all;
            };
          }
        ) { };

        oneuptime-infrastructure-agent = pkgs.callPackage (
          {
            lib,
            buildGoModule,
            fetchFromGitHub,
            nix-update-script,
          }:

          buildGoModule (finalAttrs: {
            pname = "oneuptime-infrastructure-agent";
            version = "14.0.6";

            __structuredAttrs = true;

            src = fetchFromGitHub {
              owner = "OneUptime";
              repo = "oneuptime";
              tag = finalAttrs.version;
              hash = "sha256-lAXHLVIUA4XstFSZ6h8jN8bpucrDKzHU+dVMJTDUnOQ=";
            };

            sourceRoot = "${finalAttrs.src.name}/agents/InfrastructureAgent";

            vendorHash = "sha256-44Z1GWZcSCh+AFfsxwJIMw9pqzgg2IuzkQEpCUOephk=";

            passthru.updateScript = nix-update-script { };

            meta = {
              mainProgram = "oneuptime-infrastructure-agent";
              platforms = lib.platforms.unix ++ lib.platforms.windows;
            };
          })
        ) { };

        oneuptime-kubernetes-cost-agent = pkgs.callPackage (
          {
            lib,
            buildNpmPackage,
            fetchFromGitHub,
            makeWrapper,
            nix-update-script,
            nodejs_26,
          }:

          buildNpmPackage (finalAttrs: {
            pname = "oneuptime-kubernetes-cost-agent";
            version = "14.0.6";

            __structuredAttrs = true;

            src = fetchFromGitHub {
              owner = "OneUptime";
              repo = "oneuptime";
              tag = finalAttrs.version;
              hash = "sha256-lAXHLVIUA4XstFSZ6h8jN8bpucrDKzHU+dVMJTDUnOQ=";
            };

            sourceRoot = "${finalAttrs.src.name}/agents/KubernetesCostAgent";

            nodejs = nodejs_26;

            npmDepsHash = "sha256-7YLsOl2sILhoHdfgBVgrK5HsJtEI2i9GmNi6aJB+6hw=";

            npmBuildScript = "compile";

            nativeBuildInputs = [ makeWrapper ];

            installPhase =
              let
                libDir = "$out/lib/oneuptime-kubernetes-cost-agent";
              in
              ''
                runHook preInstall

                install -d ${libDir}
                cp -a build/dist ${libDir}/

                makeWrapper ${lib.getExe nodejs_26} $out/bin/oneuptime-kubernetes-cost-agent \
                  --add-flags ${libDir}/dist/Index.js

                runHook postInstall
              '';

            passthru.updateScript = nix-update-script { };

            meta = {
              mainProgram = "oneuptime-kubernetes-cost-agent";
              platforms = lib.platforms.linux;
            };
          })
        ) { };

        oneuptime-kubernetes-log-tailer = pkgs.callPackage (
          {
            lib,
            buildNpmPackage,
            fetchFromGitHub,
            makeWrapper,
            nix-update-script,
            nodejs_26,
          }:

          buildNpmPackage (finalAttrs: {
            pname = "oneuptime-kubernetes-log-tailer";
            version = "14.0.6";

            __structuredAttrs = true;

            src = fetchFromGitHub {
              owner = "OneUptime";
              repo = "oneuptime";
              tag = finalAttrs.version;
              hash = "sha256-lAXHLVIUA4XstFSZ6h8jN8bpucrDKzHU+dVMJTDUnOQ=";
            };

            sourceRoot = "${finalAttrs.src.name}/agents/KubernetesLogTailer";

            nodejs = nodejs_26;

            npmDepsHash = "sha256-W0clepI+mCqQ7CGtW4uDXLdpdDTfXVFt3HAmN60oCm0=";

            npmBuildScript = "compile";

            # Prevent inclusion of dev deps since we override installPhase
            npmFlags = [ "--omit=dev" ];

            nativeBuildInputs = [ makeWrapper ];

            installPhase =
              let
                libDir = "$out/lib/oneuptime-kubernetes-log-tailer";
              in
              ''
                runHook preInstall

                install -d ${libDir}
                cp -a build/dist node_modules ${libDir}/

                makeWrapper ${lib.getExe nodejs_26} $out/bin/oneuptime-kubernetes-log-tailer \
                  --add-flags ${libDir}/dist/Index.js

                runHook postInstall
              '';

            passthru.updateScript = nix-update-script { };

            meta = {
              mainProgram = "oneuptime-kubernetes-log-tailer";
              platforms = lib.platforms.linux;
            };
          })
        ) { };

        oneuptime-probe = pkgs.callPackage (
          {
            lib,
            buildNpmPackage,
            dnsutils,
            fetchFromGitHub,
            fetchNpmDeps,
            iputils,
            makeWrapper,
            nodejs_26,
            playwright-driver,
            playwright-test,
            traceroute,
          }:

          let
            version = "14.0.6";

            src = fetchFromGitHub {
              owner = "OneUptime";
              repo = "oneuptime";
              tag = version;
              hash = "sha256-lAXHLVIUA4XstFSZ6h8jN8bpucrDKzHU+dVMJTDUnOQ=";
            };

            # Probe depends on Common as `file:../Common`, so npm symlinks it rather than installing it.
            commonNpmDeps = fetchNpmDeps {
              name = "oneuptime-common-npm-deps-${version}";
              src = "${src}/packages/Common";
              hash = "sha256-zOWPBxJazRMyMa8A58CPQVQgAgicvqKqDMI5UruPH+w=";
            };
          in
          buildNpmPackage {
            pname = "oneuptime-probe";
            inherit version src;

            __structuredAttrs = true;

            sourceRoot = "${src.name}/packages/Probe";

            nodejs = nodejs_26;

            npmDepsHash = "sha256-aiV48OrK8VUPTxbB4Hcz19Uy94P3UyV/HLv8wZ1qwhI=";

            # The one optional dependency is msnodesqlv8, a native driver needing unixODBC.
            npmFlags = [ "--omit=optional" ];

            nativeBuildInputs = [ makeWrapper ];

            # Common still needs the optional dependencies Probe omits
            preBuild = ''
              chmod -R u+w ../Common

              (
                export npmRoot=../Common
                export npmDeps=${commonNpmDeps}
                npmFlags=""
                npmFlagsArray=()

                npmConfigHook
              )
            '';

            dontNpmBuild = true;

            # NPM's playwright fetches browsers from a postinstall the sandbox blocks. Replace it with nixpkgs's own
            postBuild = ''
              for pkg in playwright playwright-core; do
                rm -rf node_modules/$pkg
                cp -r --no-preserve=mode ${playwright-test}/lib/node_modules/$pkg node_modules/$pkg
              done
            '';

            installPhase =
              let
                probeDir = "$out/lib/oneuptime/Probe";
              in
              ''
                runHook preInstall

                install -d $out/lib/oneuptime
                cp -a ../Common $out/lib/oneuptime/Common
                cp -a . ${probeDir}

                makeWrapper ${lib.getExe nodejs_26} $out/bin/oneuptime-probe \
                  --chdir ${probeDir} \
                  --add-flags "--no-node-snapshot" \
                  --add-flags "--require ts-node/register" \
                  --add-flags ${probeDir}/Index.ts \
                  --set TS_NODE_TRANSPILE_ONLY 1 \
                  --set APP_VERSION ${version} \
                  --set PLAYWRIGHT_BROWSERS_PATH ${
                    # Synthetic monitoring doesn't use webkit and disabling reclaims 1GB
                    playwright-driver.browsers.override { withWebkit = false; }
                  } \
                  --prefix PATH : ${
                    # Monitors shell out to these for networking checks
                    lib.makeBinPath [
                      dnsutils
                      iputils
                      traceroute
                    ]
                  }

                runHook postInstall
              '';

            meta = {
              mainProgram = "oneuptime-probe";
              platforms = lib.platforms.linux;
            };
          }
        ) { };

        oneuptime-runner = pkgs.callPackage (
          {
            lib,
            bash,
            buildNpmPackage,
            fetchFromGitHub,
            fetchNpmDeps,
            git,
            makeWrapper,
            nodejs_26,
          }:

          buildNpmPackage (finalAttrs: {
            pname = "oneuptime-runner";
            version = "14.0.6";

            __structuredAttrs = true;

            src = fetchFromGitHub {
              owner = "OneUptime";
              repo = "oneuptime";
              tag = finalAttrs.version;
              hash = "sha256-lAXHLVIUA4XstFSZ6h8jN8bpucrDKzHU+dVMJTDUnOQ=";
            };

            sourceRoot = "${finalAttrs.src.name}/packages/Runner";

            nodejs = nodejs_26;

            npmDepsHash = "sha256-nY/t5hkZxMK0J1km8o2dxAiVrNJTJfr2baEtPrnIoJU=";

            nativeBuildInputs = [ makeWrapper ];

            # unpackPhase only makes sourceRoot writable, and Common sits outside it.
            postPatch = ''
              chmod -R u+w ..
            '';

            # Runner depends on Common as `file:../Common`, so npm symlinks it rather than installing it.
            preBuild = ''
              (
                cd ../Common
                export npmDeps=${
                  fetchNpmDeps {
                    name = "oneuptime-common-npm-deps-${finalAttrs.version}";
                    src = "${finalAttrs.src}/packages/Common";
                    hash = "sha256-zOWPBxJazRMyMa8A58CPQVQgAgicvqKqDMI5UruPH+w=";
                  }
                }
                npmConfigHook
              )
            '';

            dontNpmBuild = true;

            installPhase = ''
              runHook preInstall

              install -d $out/lib/oneuptime
              cp -a ../Common $out/lib/oneuptime/Common
              cp -a . $out/lib/oneuptime/Runner

              makeWrapper ${lib.getExe nodejs_26} $out/bin/oneuptime-runner \
                --chdir $out/lib/oneuptime/Runner \
                --add-flags "--no-node-snapshot --require ts-node/register $out/lib/oneuptime/Runner/Index.ts" \
                --set TS_NODE_TRANSPILE_ONLY 1 \
                --set APP_VERSION ${finalAttrs.version} \
                --prefix PATH : ${
                  # Runbook steps run under bash, it also supports code fixes which run under git
                  lib.makeBinPath [
                    bash
                    git
                  ]
                }

              runHook postInstall
            '';

            meta = {
              mainProgram = "oneuptime-runner";
              platforms = lib.platforms.linux;
            };
          })
        ) { };
      };
    };
}

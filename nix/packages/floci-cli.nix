{ self, inputs, ... }:
{
  perSystem =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      packages.floci-cli = pkgs.buildGraalvmNativeImage (finalAttrs: {
        pname = "floci-cli";
        version = "0.2.1";

        src = pkgs.maven.buildMavenPackage {
          pname = "floci-cli-jar";
          inherit (finalAttrs) version;

          src = pkgs.fetchFromGitHub {
            owner = "floci-io";
            repo = "floci-cli";
            tag = finalAttrs.version;
            hash = "sha256-YvWCHl1vAyCmVhoB41CzDAht1DePMFkBYBRJYaZuIT4=";
          };

          mvnJdk = pkgs.jdk25;
          mvnHash = "sha256-v5QrnW0Cvfz6rNFevHqPfZ8yQFF2/6LtjiCIDoTMVgo=";

          installPhase = ''
            install -Dm644 target/floci.jar $out
          '';
        };

        # Copied from the `native` profile in pom.xml
        extraNativeImageBuildArgs = [
          "--enable-url-protocols=http,https"
          "--no-fallback"
          "-H:+ReportExceptionStackTraces"
          ''-H:IncludeResources=.*\.properties''
        ];

        nativeBuildInputs = [ pkgs.installShellFiles ];

        postInstall = ''
          installShellCompletion --cmd floci \
            --bash <($out/bin/floci completion bash) \
            --zsh <($out/bin/floci completion zsh)
        '';

        passthru.tests.version = pkgs.testers.testVersion {
          package = config.packages.floci-cli;
          command = "floci --version";
          version = "floci ${finalAttrs.version}";
        };

        meta = {
          description = "CLI to manage local AWS, Azure, GCP, and OCI cloud emulators";
          homepage = "https://github.com/floci-io/floci-cli";
          changelog = "https://github.com/floci-io/floci-cli/releases/tag/${finalAttrs.version}";
          license = lib.licenses.mit;
          maintainers = [ lib.maintainers.kashw2 ];
          mainProgram = "floci";
          platforms = [
            "x86_64-linux"
            "aarch64-linux"
            "aarch64-darwin"
          ];
        };
      });
    };
}

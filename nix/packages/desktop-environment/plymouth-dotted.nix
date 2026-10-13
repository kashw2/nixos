{ self, inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      # Video boot splash vendored from Muddyblack/NixOS (MIT). The MP4 is split
      # into PNG frames at build time and played back by a Plymouth script.
      video = ./plymouth-dotted/dotted.mp4;
      script = ./plymouth-dotted/dotted.script;
      # The source is 24 fps; motion interpolation synthesises the in-between frames.
      fps = 60;
      # 0-based indices into the 60 fps frames. The video opens on black, fades
      # in, shimmers, then fades back to black. Keep the fade-in through the end
      # of the shimmer; the script plays the fade-in once, then bounces between
      # loopStart and lastFrame so there is no dip to black between loops.
      firstFrame = 46; # first non-black frame
      loopStart = 139; # fade-in complete
      lastFrame = 504; # last frame before the fade-out
    in
    {
      packages.plymouth-dotted = pkgs.stdenvNoCC.mkDerivation {
        pname = "plymouth-theme-dotted";
        version = "1.0";

        dontUnpack = true;
        nativeBuildInputs = [
          pkgs.ffmpeg
          pkgs.pngquant
          pkgs.oxipng
        ];

        # Every frame lands in each initrd, so quantise to a 64-colour palette
        # and recompress losslessly (~51 MB vs ~280 MB of raw RGB PNGs).
        buildPhase = ''
          mkdir frames
          ffmpeg -loglevel error -filter_threads "$NIX_BUILD_CORES" -i ${video} \
            -vf 'minterpolate=fps=${toString fps}:mi_mode=mci:mc_mode=aobmc:me_mode=bidir:vsbmc=1,select=between(n\,${toString firstFrame}\,${toString lastFrame})' \
            -fps_mode passthrough frames/frame-%d.png
          find frames -name '*.png' -print0 \
            | xargs -0 -P "$NIX_BUILD_CORES" -n 1 pngquant 64 --force --ext .png --speed 3
          find frames -name '*.png' -print0 \
            | xargs -0 -P "$NIX_BUILD_CORES" -n 4 oxipng -o 4 --strip all -q
        '';

        installPhase = ''
          themedir=$out/share/plymouth/themes/dotted
          mkdir -p $themedir
          cp frames/*.png $themedir/

          cp ${script} $themedir/dotted.script
          substituteInPlace $themedir/dotted.script \
            --replace-fail FRAME_COUNT_PLACEHOLDER "$(ls frames | wc -l)" \
            --replace-fail SOURCE_FPS_PLACEHOLDER ${toString fps} \
            --replace-fail LOOP_START_PLACEHOLDER ${toString (loopStart - firstFrame)}

          cat > $themedir/dotted.plymouth <<EOF
          [Plymouth Theme]
          Name=dotted
          Description=Video boot splash: dotted
          ModuleName=script

          [script]
          ImageDir=$themedir
          ScriptFile=$themedir/dotted.script
          EOF
        '';
      };
    };
}

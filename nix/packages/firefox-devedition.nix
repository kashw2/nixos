{ ... }:
{
  flake.wrappers.firefox-devedition =
    { pkgs, wlib, ... }:
    {
      imports = [ wlib.modules.default ];
      config = {
        # Take webcams through the camera portal and PipeWire instead of opening
        # /dev/video* directly. A UVC camera streams to one V4L2 client at a time,
        # so direct access fails whenever OBS holds it; PipeWire shares the node.
        package = pkgs.firefox-devedition.override {
          extraPrefs = ''
            defaultPref("media.webrtc.camera.allow-pipewire", true);
          '';
        };
      };
    };
}

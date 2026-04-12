{ self, inputs, ... }:
{
  flake.wrappers.rofi =
    {
      pkgs,
      wlib,
      lib,
      ...
    }:
    {
      imports = [ wlib.wrapperModules.rofi ];
      config = {
        settings = {
          location = 0;
          xoffset = 0;
          yoffset = 0;
        };
        theme = toString (
          pkgs.writeText "rofi-theme.rasi" ''
            window {
                fullscreen: true;
            }

            * {
                selected-normal-foreground:  rgba ( 238, 238, 255, 100 % );
                foreground:                  rgba ( 125, 125, 125, 100 % );
                normal-foreground:           @foreground;
                alternate-normal-background: rgba ( 0, 0, 0, 1 % );
                red:                         rgba ( 220, 50, 47, 100 % );
                selected-urgent-foreground:  rgba ( 216, 222, 233, 100 % );
                blue:                        rgba ( 38, 139, 210, 100 % );
                urgent-foreground:           rgba ( 216, 222, 233, 100 % );
                alternate-urgent-background: rgba ( 0, 0, 0, 1 % );
                active-foreground:           rgba ( 216, 222, 233, 100 % );
                lightbg:                     rgba ( 238, 232, 213, 100 % );
                selected-active-foreground:  rgba ( 216, 222, 233, 100 % );
                alternate-active-background: rgba ( 0, 0, 0, 1 % );
                background:                  rgba ( 0, 0, 0, 20 % );
                alternate-normal-foreground: @foreground;
                normal-background:           rgba ( 0, 0, 0, 1 % );
                lightfg:                     rgba ( 88, 104, 117, 100 % );
                selected-normal-background:  rgba ( 0, 0, 0, 1 % );
                border-color:                rgba ( 41, 47, 55, 0 % );
                spacing:                     0;
                separatorcolor:              rgba ( 255, 255, 255, 60 % );
                urgent-background:           rgba ( 0, 0, 0, 1 % );
                selected-urgent-background:  rgba ( 0, 0, 0, 1 % );
                alternate-urgent-foreground: @urgent-foreground;
                background-color:            rgba ( 0, 0, 0, 0 % );
                alternate-active-foreground: @active-foreground;
                active-background:           rgba ( 0, 0, 0, 1 % );
                selected-active-background:  rgba ( 0, 0, 0, 1 % );
            }
            #window {
                background-color: @background;
                border:           3;
                padding:          200;
            }
            #mainbox {
                border:  0;
                padding: 10px;
            }
            #message {
                border:       2px 0px 0px ;
                border-color: @separatorcolor;
                padding:      1px ;
            }
            #textbox {
                text-color: @foreground;
            }

            #listview {
                fixed-height: 0;
                border:       2px 0px 0px ;
                border-color: @separatorcolor;
                spacing:      10px ;
                scrollbar:    false;
                padding:      20px 0px 0px ;
            }
            #element {
                border:  0;
                padding: 1px ;
            }
            #element-text {
                text-color: inherit;
            }
            #element.normal.normal {
                background-color: @normal-background;
                text-color:       @normal-foreground;
            }
            #element.normal.urgent {
                background-color: @urgent-background;
                text-color:       @urgent-foreground;
            }
            #element.normal.active {
                background-color: @active-background;
                text-color:       @active-foreground;
            }
            #element.selected.normal {
                background-color: @selected-normal-background;
                text-color:       @selected-normal-foreground;
            }
            #element.selected.urgent {
                background-color: @selected-urgent-background;
                text-color:       @selected-urgent-foreground;
            }
            #element.selected.active {
                background-color: @selected-active-background;
                text-color:       @selected-active-foreground;
            }
            #element.alternate.normal {
                background-color: @alternate-normal-background;
                text-color:       @alternate-normal-foreground;
            }
            #element.alternate.urgent {
                background-color: @alternate-urgent-background;
                text-color:       @alternate-urgent-foreground;
            }
            #element.alternate.active {
                background-color: @alternate-active-background;
                text-color:       @alternate-active-foreground;
            }
            #scrollbar {
                width:        4px ;
                border:       0;
                handle-color: @normal-foreground;
                padding:      0;
            }
            #sidebar {
                border:       2px 0px 0px ;
                border-color: @separatorcolor;
            }
            #button {
                spacing:    0;
                text-color: @normal-foreground;
            }
            #button.selected {
                background-color: @selected-normal-background;
                text-color:       @selected-normal-foreground;
            }
            #inputbar {
                spacing:    20;
                text-color: @normal-foreground;
                padding:    10px 10px;
            }
            #case-indicator {
                spacing:    0;
                text-color: @normal-foreground;
            }
            #entry {
                spacing:    0;
                text-color: @normal-foreground;
            }
            #prompt {
                spacing:    0;
                text-color: @normal-foreground;
            }
          ''
        );
      };
    };
}

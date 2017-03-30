import XMonad
import XMonad.Util.EZConfig(additionalKeys)
import XMonad.Wallpaper
import XMonad.Actions.Volume
import XMonad.Util.Dzen
import Graphics.X11.ExtraTypes.XF86

main :: IO()
main = do
    setRandomWallpaper ["${HOME}/Pictures/Paintings/"]
    xmonad $ defaultConfig
        { terminal    = "gnome-terminal"
        -- Borders
        , borderWidth = 2
        , normalBorderColor = "#cccccc"
        , focusedBorderColor = "#00ff00"
        } `additionalKeys`
        [ ((mod1Mask .|. controlMask, xK_l), spawn "slock")
        , ((0, xF86XK_MonBrightnessUp  ), spawn "xbacklight -inc 5")
        , ((0, xF86XK_MonBrightnessDown), spawn "xbacklight -dec 5")
        , ((0, xF86XK_AudioLowerVolume), spawn "amixer -D pulse -- sset Master unmute 5%-")
        , ((0, xF86XK_AudioRaiseVolume), spawn "amixer -D pulse -- sset Master unmute 5%+")
        , ((0, xF86XK_AudioMute       ), spawn "amixer -D pulse -- sset Master toggle")
        , ((0, xF86XK_AudioMicMute    ), spawn "amixer -D pulse -- sset Capture toggle")
        ]

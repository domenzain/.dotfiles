import XMonad
import XMonad.Actions.CycleWS
import XMonad.StackSet
import XMonad.Util.EZConfig(additionalKeys)
import XMonad.Util.WorkspaceCompare
import XMonad.Wallpaper.Expand
import XMonad.Wallpaper.Find
import XMonad.Prompt
import XMonad.Prompt.Pass
import System.Random
import Graphics.X11.ExtraTypes.XF86

setRandomWallpaper :: [String] -> IO()
setRandomWallpaper filepaths = do
    rootPaths  <- mapM expand filepaths
    candidates <- findImages rootPaths
    wallpaper  <- ((!!) candidates) <$> getStdRandom (randomR (0, length candidates - 1))
    spawn $ "feh --bg-fill " ++ wallpaper

-- TODO: get $EDITOR and pass it on
editor :: String
editor = "emacsclient -c"

rotateWS :: Bool -> X()
rotateWS b  = do t <- findWorkspace getSortByIndex (bToDir b) NonEmptyWS 1
                 windows . greedyView $ t
  where bToDir True  = Next
        bToDir False = Prev

main :: IO()
main = do
    setRandomWallpaper ["${HOME}/Pictures/Paintings/"]
    xmonad $ def
        { terminal    = "gnome-terminal"
        -- Borders
        , borderWidth = 2
        , normalBorderColor = "#cccccc"
        , focusedBorderColor = "#00ff00"
        } `additionalKeys`
        [ ((mod1Mask .|. controlMask, xK_l), spawn "slock")
        , ((mod1Mask, xK_Tab), rotateWS True)
        , ((mod1Mask .|. shiftMask, xK_Tab), rotateWS False)
        -- Media buttons
        , ((0, xF86XK_MonBrightnessUp  ), spawn "light -A 5")
        , ((0, xF86XK_MonBrightnessDown), spawn "light -U 5")
        , ((0, xF86XK_AudioLowerVolume), spawn "amixer -D pulse -- sset Master unmute 5%-")
        , ((0, xF86XK_AudioRaiseVolume), spawn "amixer -D pulse -- sset Master unmute 5%+")
        , ((0, xF86XK_AudioMute       ), spawn "amixer -D pulse -- sset Master toggle")
        , ((0, xF86XK_AudioMicMute    ), spawn "amixer -D pulse -- sset Capture toggle")
        -- Shortcuts
        , ((mod1Mask, xK_m), spawn ("EDITOR='" ++ editor ++ "' gnome-terminal -e mutt"))
        , ((mod1Mask .|. controlMask, xK_e), spawn editor)
        , ((mod1Mask .|. shiftMask, xK_p), passPrompt $ def
            { position = CenteredAt (1/4) (2/3)
            , font = "xft:Source Code Pro-9"
            })]

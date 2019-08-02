import XMonad
import XMonad.Actions.CycleWS
import XMonad.Actions.PhysicalScreens
import XMonad.StackSet
import XMonad.Util.WorkspaceCompare
import XMonad.Wallpaper.Expand
import XMonad.Wallpaper.Find
import XMonad.Prompt
import XMonad.Prompt.Pass
import XMonad.Layout
import XMonad.Layout.Accordion
import XMonad.Layout.Grid
import System.Random
import Graphics.X11.ExtraTypes.XF86
import qualified Data.Map as M
import System.Exit (exitSuccess )

setRandomWallpaper :: [String] -> IO()
setRandomWallpaper filepaths = do
    rootPaths  <- mapM expand filepaths
    candidates <- findImages rootPaths
    wallpaper  <- (!!) candidates <$> getStdRandom (randomR (0, length candidates - 1))
    spawn $ "feh --bg-fill " ++ wallpaper

-- TODO: get $EDITOR and pass it on
editor :: String
editor = "emacsclient -c"

rotateWS :: Bool -> X()
rotateWS b  = do t <- findWorkspace getSortByIndex (bToDir b) NonEmptyWS 1
                 windows . greedyView $ t
  where bToDir True  = Next
        bToDir False = Prev

myKeys :: XConfig Layout -> M.Map (KeyMask, KeySym) (X ())
myKeys configDefault@XConfig {XMonad.modMask = configModMask} = M.fromList
  [ ((configModMask, xK_l), spawn "slock")
  , ((configModMask, xK_Tab), rotateWS True)
  , ((configModMask .|. shiftMask, xK_Tab), rotateWS False)
    -- Media buttons
  , ((0, xF86XK_MonBrightnessUp  ), spawn "light -A 5")
  , ((0, xF86XK_MonBrightnessDown), spawn "light -U 5")
  , ((0, xF86XK_AudioLowerVolume ), spawn "amixer -D pulse -- sset Master unmute 5%-")
  , ((0, xF86XK_AudioRaiseVolume ), spawn "amixer -D pulse -- sset Master unmute 5%+")
  , ((0, xF86XK_AudioMute        ), spawn "amixer -D pulse -- sset Master toggle")
  , ((0, xF86XK_AudioMicMute     ), spawn "amixer -D pulse -- sset Capture toggle")
    -- Displays
  , ((configModMask, xK_Left), onPrevNeighbour verticalScreenOrderer view)
  , ((configModMask, xK_Right), onNextNeighbour verticalScreenOrderer view)
  , ((configModMask .|. shiftMask, xK_Left),
      onPrevNeighbour verticalScreenOrderer shift
      >> onPrevNeighbour verticalScreenOrderer view)
  , ((configModMask .|. shiftMask, xK_Right),
      onNextNeighbour verticalScreenOrderer shift
      >> onNextNeighbour verticalScreenOrderer view)
    -- Windows and programs
  , ((configModMask, xK_Up                  ), windows focusUp)
  , ((configModMask, xK_Down                ), windows focusDown)
  , ((configModMask .|. shiftMask, xK_Up    ), windows swapUp)
  , ((configModMask .|. shiftMask, xK_Down  ), windows swapDown)
  , ((configModMask .|. shiftMask, xK_c     ), kill)
  , ((configModMask,               xK_space ), sendMessage NextLayout)

  , ((configModMask .|. shiftMask, xK_space ), setLayout $ XMonad.layoutHook configDefault)
  , ((configModMask .|. shiftMask, xK_Return), spawn $ XMonad.terminal configDefault)
  , ((configModMask,               xK_p     ), spawn "dmenu_run")
  , ((configModMask .|. shiftMask, xK_p     ), spawn "gmrun")

  , ((configModMask, xK_n), refresh) -- %! Resize viewed windows to the correct size

  -- move focus up or down the window stack
  , ((configModMask, xK_m), windows focusMaster)

  -- modifying the window order
  , ((configModMask, xK_Return), windows swapMaster)

  -- resizing the master/slave ratio
  , ((configModMask, xK_comma), sendMessage Shrink)
  , ((configModMask, xK_period), sendMessage Expand)

  -- floating layer support
  , ((configModMask, xK_t     ), withFocused $ windows . sink)

  -- increase or decrease number of windows in the master area
  , ((configModMask .|. shiftMask, xK_comma), sendMessage (IncMasterN 1))
  , ((configModMask .|. shiftMask, xK_period), sendMessage (IncMasterN (-1)))

  -- quit, or restart
  , ((configModMask .|. shiftMask, xK_q     ), io exitSuccess)  -- %! Quit xmonad
  , ((configModMask              , xK_q     ), spawn "if type xmonad; then xmonad --recompile && xmonad --restart; else xmessage xmonad not in \\$PATH: \"$PATH\"; fi") -- %! Restart xmonad

  , ((configModMask, xK_e), spawn editor)
  , ((configModMask .|. shiftMask, xK_p), passPrompt $ def
                                     { position = CenteredAt (1/4) (2/3)
                                     , font = "xft:Source Code Pro-9"
                                     })
  ]


myLayout = Mirror tiled ||| Grid ||| Accordion ||| Full
    where
      tiled = Tall nmaster delta ratio
      nmaster = 1
      ratio = 2/3
      delta = 1/100

main :: IO()
main = do
    setRandomWallpaper ["${HOME}/Pictures/Paintings/"]
    xmonad $ def
      { terminal    = "gnome-terminal"
                    -- Borders
    , borderWidth = 2
    , normalBorderColor = "#cccccc"
    , focusedBorderColor = "#00ff00"
    , modMask = mod4Mask
    , keys = myKeys
    , layoutHook = myLayout
    }

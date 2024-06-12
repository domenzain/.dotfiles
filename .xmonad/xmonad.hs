import qualified Data.Map                       as M
import           Graphics.X11.ExtraTypes.XF86
import           System.Exit                    (exitSuccess)
import           XMonad
import           XMonad.Actions.CycleWS
import           XMonad.Actions.PhysicalScreens
import           XMonad.Hooks.EwmhDesktops
import           XMonad.Layout.Grid
import           XMonad.Prompt
import           XMonad.Prompt.Pass
import           XMonad.StackSet
import           XMonad.Util.WorkspaceCompare

-- TODO: get $EDITOR and pass it on
editor :: String
editor = "/snap/bin/emacsclient -c"

rotateWS :: Bool -> X()
rotateWS b  = do t <- findWorkspace getSortByIndex (bToDir b) NonEmptyWS 1
                 windows . greedyView $ t
  where bToDir True  = Next
        bToDir False = Prev

myKeys :: XConfig Layout -> M.Map (KeyMask, KeySym) (X ())
myKeys configDefault@XConfig {XMonad.modMask = configModMask} = M.fromList $
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
  , ((configModMask .|. shiftMask, xK_q), io exitSuccess)  -- %! Quit xmonad
  , ((configModMask              , xK_q),
     spawn "if type xmonad; then xmonad --recompile && xmonad --restart; else xmessage xmonad not in \\$PATH: \"$PATH\"; fi") -- %! Restart xmonad

  , ((configModMask, xK_e), spawn editor)
  , ((configModMask, xK_f), spawn "firefox")
  , ((configModMask .|. shiftMask, xK_p), passPrompt $ def
                                     { position = CenteredAt (1/4) (2/3)
                                     , font = "xft:Source Code Pro-9"
                                     })
  ] ++
  [ ((m .|. configModMask, k), windows $ f i)
  | (i, k) <- zip (XMonad.workspaces configDefault) [xK_1 .. xK_9]
  , (f, m) <- [(greedyView, 0), (shift, shiftMask)]
  ]


myLayout :: Choose Grid (Choose (Mirror Tall) (Choose Tall Full)) a
myLayout = Grid ||| Mirror tiled ||| tiled ||| Full
    where
      tiled = Tall nmaster delta ratio
      nmaster = 1
      ratio = 2/3
      delta = 1/100

main :: IO()
main = do
  xmonad $ ewmh $ def
    { terminal    = "gnome-terminal"
    , borderWidth = 2
    , normalBorderColor = "#cccccc"
    , focusedBorderColor = "#00ff00"
    , modMask = mod4Mask
    , keys = myKeys
    , layoutHook = myLayout
    -- TODO: use ewmhFullscreen when stack upgrades xmonad-contrib
    , handleEventHook = handleEventHook def <+> fullscreenEventHook
    }

module Keys where

import qualified Data.Map as M
import Data.Map.Merge.Lazy
import Scratchpads (myScratchpads)
import Workspaces
import XMonad
import XMonad.Actions.AfterDrag
import XMonad.Actions.CopyWindow (copy, killAllOtherCopies)
import XMonad.Actions.CycleRecentWS
import XMonad.Actions.FloatSnap
import XMonad.Actions.Minimize
import XMonad.Actions.Submap
import XMonad.Config.Dmwit
import qualified XMonad.Config.Prime as Xmonad.Config.Prime
import XMonad.Layout.IndependentScreens
import qualified XMonad.StackSet as W
import XMonad.Util.EZConfig
import XMonad.Util.NamedScratchpad
import qualified XMonad.Prelude as L
import Data.List (find)
import qualified Debug.Trace as Debug
import XMonad.Actions.OnScreen (greedyViewOnScreen, viewOnScreen)

myMouseBindings XConfig {XMonad.modMask = modm} =
  M.fromList
    -- mod-button1, Set the window to floating mode and move by dragging
    [ ((modm, button1), \w -> focus w >> mouseMoveWindow w >> ifClick (snapMagicMove (Just 50) (Just 50) w)),
      ((modm .|. shiftMask, button1), \w -> focus w >> mouseMoveWindow w >> ifClick (snapMagicResize [L, R, U, D] (Just 50) (Just 50) w)),
      ((modm, button3), \w -> focus w >> mouseResizeWindow w >> ifClick (snapMagicResize [R, D] (Just 50) (Just 50) w)),
      -- ( (modm, button1),
      --   \w ->
      --     focus w >> mouseMoveWindow w
      --       >> windows W.shiftMaster
      -- ),
      -- -- mod-button2, Raise the window to the top of the stack
      -- ((modm, button2), \w -> focus w >> windows W.shiftMaster),
      -- -- mod-button3, Set the window to floating mode and resize by dragging
      -- ( (modm, button3),
      --   \w ->
      --     focus w >> mouseResizeWindow w
      --       >> windows W.shiftMaster
      -- ),
      -- you may also bind events to the mouse scroll wheel (button4 and button5)
      ((modm, button4), \w -> focus w >> windows W.focusDown),
      ((modm .|. altMask, button4), \w -> focus w >> windows W.swapDown),
      ((modm .|. altMask, button5), \w -> focus w >> windows W.swapUp),
      ((modm, button5), \w -> focus w >> windows W.focusUp)
    ]

functionKeys =
  [ ("<XF86AudioRaiseVolume>", spawn "pactl set-sink-volume @DEFAULT_SINK@ +10%"),
    ("<XF86AudioLowerVolume>", spawn "pactl set-sink-volume @DEFAULT_SINK@ -10%"),
    ("<XF86AudioMute>", spawn "pactl set-sink-mute @DEFAULT_SINK@ toggle"),
    ("<XF86AudioMicMute>", spawn "pactl set-source-mute @DEFAULT_SOURCE@ toggle"),
    ("<XF86MonBrightnessUp>", spawn "brightnessctl s +10%"),
    ("<XF86MonBrightnessDown>", spawn "brightnessctl s 10%-"),
    ("<XF86AudioPlay>", spawn "--no-startup-id dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlayPause"),
    ("<XF86AudioPause>", spawn "--no-startup-id dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Pause"),
    ("<XF86AudioNext>", spawn "--no-startup-id dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Next"),
    ("<XF86AudioPrev>", spawn "--no-startup-id dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Previous")
  ]

screenshotAndRecordKeys =
  [ ("<Print>", spawn "flameshot gui --delay=1000"),
    ("C-<Print>", spawn "fish -c 'flameshot full -c'"),
    ("<Pause>", spawn "fish -c 'record'"),
    ("C-<Pause>", spawn "fish -c 'record_screen'")
  ]

keysP =
  functionKeys
    ++ screenshotAndRecordKeys
    ++ [ ("M-d", spawn "~/.config/rofi/launchers/colorful/launcher.sh"),
         ("M-c", namedScratchpadAction myScratchpads "calc"),
         ("M-M1-t", namedScratchpadAction myScratchpads "chat"),
         ("M-x", kill),
         ("F12", spawn "guake-toggle"),
         ("M-S-h", sendMessage Shrink),
         ("M-S-l", sendMessage Expand),
         ("M-z", withLastMinimized' toggleMaximization),
         ("M-t", withFocused toggleFloat),
         ("M-e", spawn "emacsclient --eval \"(emacs-everywhere)\""),
         ("M-a", windows copyToSecondScreen),
         ("M-S-a", killAllOtherCopies),
         ("M-S-t", spawn "killall my-taffybar;my-taffybar")
       ]

shiftThenView i = W.view i . W.shift i

screenShiftThenView :: PhysicalWorkspace -> WindowSet -> WindowSet
screenShiftThenView i =  viewOnScreen (unmarshallS i) i . W.shift i

screenView i =
  viewOnScreen (unmarshallS i) i -- < https://xmonad.github.io/xmonad-docs/xmonad-contrib/XMonad-Actions-OnScreen.html

windowsKeysForSwitchingAndMovingOnWorkspaces =
  [ ( (m .|. mod4Mask, k), windows $ f i)
    | (i, k) <- zip myWorkspaces ([xK_1 .. xK_9] ++ [xK_0]),
      (f, m) <- [(screenView, 0), (screenShiftThenView, shiftMask)]
  ]

monitorsKeysForSwitchingAndMoving =
  [ ((m .|. mod4Mask, key), screenWorkspace sc >>= flip whenJust (windows . f))
    | (key, sc) <- zip [xK_h, xK_l] [0 ..],
      (f, m) <- [(W.view, 0), (shiftThenView, altMask)]
  ]

windowSnappingKeys =
  [ ( (mod4Mask, xK_f),
      submap . M.fromList $
        [ ((mod4Mask, xK_l), withFocused $ snapMove R Nothing),
          ((mod4Mask, xK_h), withFocused $ snapMove L Nothing),
          ((mod4Mask, xK_k), withFocused $ snapMove U Nothing),
          ((mod4Mask, xK_j), withFocused $ snapMove D Nothing)
        ]
    ),
    ((mod4Mask, xK_Left), withFocused $ snapMove L Nothing),
    ((mod4Mask, xK_Right), withFocused $ snapMove R Nothing),
    ((mod4Mask, xK_Up), withFocused $ snapMove U Nothing),
    ((mod4Mask, xK_Down), withFocused $ snapMove D Nothing)
  ]

keys =
  windowsKeysForSwitchingAndMovingOnWorkspaces
    ++ monitorsKeysForSwitchingAndMoving
    ++ windowSnappingKeys
    ++ [ ((mod4Mask .|. altMask, xK_j), windows W.swapDown),
         ((mod4Mask .|. altMask, xK_k), windows W.swapUp)
       ]

toggleMaximization :: Maybe Xmonad.Config.Prime.Window -> X ()
toggleMaximization window =
  case window of
    Nothing -> withFocused minimizeWindow
    Just w -> maximizeWindowAndFocus w

toggleFloat w =
  windows
    ( \s ->
        if M.member w (W.floating s)
          then W.sink w s
          else W.float w (W.RationalRect 0.15 0.15 0.65 0.65) s
    )

-- copyToSecondScreen ::  a -> a
copyToSecondScreen s =
  foldr copy s (XMonad.Layout.IndependentScreens.withScreen 1 ["6", "7", "8", "9", "10"])

myKeys :: XConfig a -> XConfig a
myKeys c =
  c {mouseBindings = myMouseBindings}
    `additionalKeysP` Keys.keysP
      `additionalKeys` Keys.keys

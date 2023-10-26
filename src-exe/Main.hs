{-# LANGUAGE OverloadedStrings #-}

module Main where

import Control.Monad
import Data.Aeson ((.=))
import Data.Aeson qualified as Json
import Data.IORef
import Data.Text (Text)
import Data.Text qualified as Text
import Data.Text.IO qualified as Text
import Network.WebSockets qualified as WS
import System.Environment qualified as Env
import System.IO (BufferMode (..), hSetBuffering, stdout)

main :: IO ()
main = do
    hSetBuffering stdout LineBuffering
    WS.runClient "irc-ws.chat.twitch.tv" 80 "/" $ \conn -> do
        putStrLn "connected!"
        login conn
        msg :: Text <- WS.receiveData conn
        Text.putStrLn msg
        WS.sendTextData @Text conn "JOIN #kenran__"
        forever $ do
            m :: Text <- WS.receiveData conn
            Text.putStrLn m

login conn = do
    pw <- Text.readFile "token"
    WS.sendTextData conn $ "PASS oauth:" <> pw
    WS.sendTextData @Text conn "NICK kenranbot"
    putStrLn "logged in!"

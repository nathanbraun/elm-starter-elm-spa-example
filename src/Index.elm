module Index exposing (htmlToReinject, index)

import Html.String exposing (..)
import Html.String.Attributes exposing (..)
import Html.String.Extra exposing (..)
import Main
import Starter.ConfMeta
import Starter.FileNames
import Starter.Flags
import Starter.Icon
import Starter.SnippetCss
import Starter.SnippetHtml
import Starter.SnippetJavascript


index : Starter.Flags.Flags -> Html msg
index flags =
    let
        relative =
            Starter.Flags.toRelative flags

        fileNames =
            Starter.FileNames.fileNames flags.version flags.commit
    in
    html
        [ lang "en" ]
        [ head []
            ([]
                ++ [ meta [ charset "utf-8" ] []
                   , title_ [] [ text flags.nameLong ]
                   , meta [ name "author", content flags.author ] []
                   , meta [ name "description", content flags.description ] []
                   , meta [ name "viewport", content "width=device-width, initial-scale=1, shrink-to-fit=no" ] []
                   , meta [ httpEquiv "x-ua-compatible", content "ie=edge" ] []
                   , link [ rel "icon", href (Starter.Icon.iconFileName relative 64) ] []
                   , link [ rel "apple-touch-icon", href (Starter.Icon.iconFileName relative 152) ] []
                   , style_ []
                        [ text <| """
                            body 
                                { background-color: """ ++ Starter.Flags.toThemeColor flags ++ """
                                ; font-family: 'IBM Plex Sans', helvetica, sans-serif
                                ; margin: 0px;
                                }""" ]
                   ]
                ++ Starter.SnippetHtml.messagesStyle
                ++ Starter.SnippetHtml.pwa
                    { commit = flags.commit
                    , relative = relative
                    , themeColor = Starter.Flags.toThemeColor flags
                    , version = flags.version
                    }
                ++ Starter.SnippetHtml.previewCards
                    { commit = flags.commit
                    , flags = flags
                    , mainConf = Main.conf
                    , version = flags.version
                    }
            )
        , body [] <| htmlToReinject flags
        ]


htmlToReinject : Starter.Flags.Flags -> List (Html.String.Html msg)
htmlToReinject flags =
    let
        relative =
            Starter.Flags.toRelative flags

        fileNames =
            Starter.FileNames.fileNames flags.version flags.commit
    in
    []
        -- Friendly message in case Javascript is disabled
        ++ (if flags.env == "dev" then
                Starter.SnippetHtml.messageYouNeedToEnableJavascript

            else
                Starter.SnippetHtml.messageEnableJavascriptForBetterExperience
           )
        -- Initializing "window.ElmStarter"
        ++ [ script [] [ textUnescaped <| Starter.SnippetJavascript.metaInfo flags ] ]
        -- Loading Elm code
        ++ [ script [ src (relative ++ fileNames.outputCompiledJsProd) ] [] ]
        -- Elm finished to load, de-activating the "Loading..." message
        -- ++ Starter.SnippetHtml.messageLoadingOff
        -- Loading utility for pretty console formatting
        ++ Starter.SnippetHtml.prettyConsoleFormatting relative flags.env
        -- Signature "Made with ??? and Elm"
        ++ [ Html.String.Extra.script [] [ Html.String.textUnescaped Starter.SnippetJavascript.signature ] ]
        -- Let's start Elm!
        ++ [ Html.String.Extra.script []
                [ Html.String.textUnescaped
                    ("""
                        // Need to remove this node otherwise Elm doesn't work
                        // because it seems that Elm detect that a similar part
                        // of the DOM already exists and it trys to hydrate, but
                        // the code is buggy.
                        // Infact, not removing this node, the links in the
                        // application reload the browser also if they are
                        // internal.

                        var node = document.getElementById('elm');
                        if (node) { node.remove(); }

                        window.ElmApp = Elm.Main.init(
                            { flags:
                                
                                // From package.jspn
                                { starter : """
                        ++ Starter.SnippetJavascript.metaInfoData flags
                        ++ """ 
                                
                                // Others
                                , width: window.innerWidth
                                , height: window.innerHeight
                                , languages: window.navigator.userLanguages || window.navigator.languages || []
                                , locationHref: location.href
                                }
                            }
                        );"""
                        ++ Starter.SnippetJavascript.portChangeMeta
                    )
                ]
           ]
        -- Register the Service Worker, we are a PWA!
        ++ [ Html.String.Extra.script [] [ Html.String.textUnescaped (Starter.SnippetJavascript.registerServiceWorker relative) ] ]

module Client exposing (main)

import Browser
import Html exposing (..)
import Http
import RemoteData exposing (WebData)


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }


type alias Model =
    WebData String


init : () -> ( Model, Cmd Msg )
init _ =
    ( RemoteData.Loading
    , Http.post
        { url = "http://localhost:8080"
        , body = Http.emptyBody
        , expect = Http.expectString (RemoteData.fromResult >> GotText)
        }
    )


type Msg
    = GotText (WebData String)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotText response ->
            ( response, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


view : Model -> Html Msg
view model =
    case model of
        RemoteData.Success fullText ->
            pre [] [ text fullText ]

        RemoteData.Failure reason ->
            div []
                [ h1 [] [ text "An error occured" ]
                , pre [] [ text <| Debug.toString reason ]
                ]

        _ ->
            text "Loading..."

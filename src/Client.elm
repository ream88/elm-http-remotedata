module Client exposing (main)

import Browser
import Html exposing (..)
import Http
import Json.Decode as JD
import RemoteData exposing (RemoteData)


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }


type alias Model =
    RemoteData Error String


type Error
    = ValidationFailed
    | Fatal Http.Error


init : () -> ( Model, Cmd Msg )
init _ =
    ( RemoteData.Loading
    , Http.post
        { url = "http://localhost:8080"
        , body = Http.emptyBody
        , expect = expectJsonResponseOrError (RemoteData.fromResult >> RemoteData.mapError mapError >> GotText)
        }
    )


errorsDecoder : JD.Decoder Error
errorsDecoder =
    JD.string
        |> JD.field "error"
        |> JD.andThen
            (\error ->
                case error of
                    "validation-failed" ->
                        JD.succeed ValidationFailed

                    err ->
                        JD.fail ("Unknown error: " ++ err)
            )


mapError : Http.Error -> Error
mapError httpError =
    case httpError of
        Http.BadBody body ->
            body
                |> JD.decodeString errorsDecoder
                |> Result.withDefault (Fatal <| Http.BadBody body)

        err ->
            Fatal err


expectJsonResponseOrError : (Result Http.Error String -> msg) -> Http.Expect msg
expectJsonResponseOrError toMsg =
    Http.expectStringResponse toMsg <|
        \response ->
            case response of
                Http.BadUrl_ url ->
                    Err (Http.BadUrl url)

                Http.Timeout_ ->
                    Err Http.Timeout

                Http.NetworkError_ ->
                    Err Http.NetworkError

                Http.BadStatus_ { statusCode } body ->
                    if statusCode == 422 then
                        Err (Http.BadBody body)

                    else
                        Err (Http.BadStatus statusCode)

                Http.GoodStatus_ metadata body ->
                    Ok body


type Msg
    = GotText (RemoteData Error String)


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

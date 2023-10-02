module InterviewWithXFDF exposing (..)



import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onClick)
import Inquisimin exposing (..)
import XFDF exposing (..)
import File.Download as Download

type alias FormContents = 
    { name : String
    , pet : String
    }

type alias Model = 
    { name : Question String 
    , pet : Question String
    }

type Msg = SaveName
         | UpdateName String
         | UpdatePet String
         | SavePet
         | DownloadXFDF String


main : Program () Model Msg
main = Browser.element 
    { init = init 
    , update = update 
    , subscriptions = subscriptions
    , view = view}


subscriptions :  Model -> Sub Msg
subscriptions _ = Sub.none

update : Msg -> Model -> (Model, Cmd Msg)
update msg model = 
    case msg of
        SaveName -> ({ model | name = completeQuestion model.name }, Cmd.none)
        SavePet -> ({ model | pet = completeQuestion model.pet }, Cmd.none)
        UpdateName str -> ({ model | name = updateQuestion str model.name }, Cmd.none)
        UpdatePet str -> ({ model | pet = updateQuestion str model.pet }, Cmd.none)
        DownloadXFDF str -> (model, downloadXFDF str)


downloadXFDF : String -> Cmd Msg
downloadXFDF xfdf =
    Download.string "data.xfdf" "application/xml" xfdf

init : () -> (Model, Cmd Msg)
init _ = 
    ( Model (mkq alwaysValid) (mkq alwaysValid)
    , Cmd.none )

interviewSteps m_ = m_ 
    |> ask nameQ
    |> ask petQ


myinterview m = Interview 
    m
    interviewSteps
    downloadForm
    
parseFormContents : Model -> Maybe FormContents
parseFormContents model = case (model.name, model.pet) of 
    (Answered name _ _, Answered pet _ _) -> Just <| FormContents name pet
    _ -> Nothing

formContentsToXFDF : FormContents -> XFDF
formContentsToXFDF fc = XFDF "example.pdf" [XField "Name" fc.name, XField "Pet" fc.pet]

getXFDF : Model -> Maybe String
getXFDF model = 
    let
        formContentsM = parseFormContents model
    in 
        case formContentsM of 
            Nothing -> Nothing
            Just formContents -> Just << xfdfToString << formContentsToXFDF <| formContents


downloadForm model = 
    let 
        xfdfM = getXFDF model
    in
        case xfdfM of 
            Nothing -> div [] 
                [text "Parsing failed. Boo."]
            Just xfdf -> div []
                [ text "Parsing Succeeded. Click to download data file" 
                , button [onClick <| DownloadXFDF xfdf ] [text "Download"]] 


--- views

view : Model -> Html Msg
view model =
    div [] [
        div []
            [ displayModelSoFar model ],
        div []
            --[ doInterview model]
            [runInterview (myinterview model)]
            ]
            

displayModelSoFar : Model -> Html msg
displayModelSoFar model = 
    div [] 
        [ div []
            [ div [] [(text "Name:"),  (text << getQValue) model.name]]
        , div []
            [ div [] [text "Pet:", (text << getQValue) (model.pet) ]]
       ]




nameQ model = case model.name of 
    Answered _ _ _ -> Continue model
    Unanswered txt f err -> Ask (
        div [] 
            [ input [placeholder "your name", value txt, onInput UpdateName] [] 
            , text err
            , button [onClick SaveName] [text "Continue"]
            ]
        )

petQ model = case model.pet of 
    Answered _ _ _ -> Continue model
    Unanswered txt f err -> Ask (
        div [] 
            [ input [placeholder "your pet's name", value txt, onInput UpdatePet] [] 
            , text err
            , button [onClick SavePet] [text "Continue"]
            ]
        )

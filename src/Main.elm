module Main exposing (..)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onClick)
import Maybe

type Either a b = Left a 
                | Right b


main : Program () Model Msg
main = Browser.sandbox {init = init, update = update, view = view}



view : Model -> Html Msg
view model =
    div [] [
        div []
            [ displayInterview model.interview ],
        div []
            [ doInterview model]
            ]


doInterview : Model -> (Html Msg)
doInterview model = 
    Left model
    |> ask askName      
    |> ask gatherFruits
    |> ask cakeordeath 
    |> finish


cakeordeath : Model -> Either Model (Html Msg)
cakeordeath model = case model.interview.cakeOrDeath of
    Nothing -> chooseCakeOrDeath
    Just chosen -> if chosen == Cake 
                    -- if chose cake, then we have some followups.
                   then (cakeChoice model) 
                   else Left model


chooseCakeOrDeath : Either Model (Html Msg)
chooseCakeOrDeath =
    Right (div [] 
        [ button [onClick ChooseDeath] [text "Death, please"]
        , button [onClick ChooseCake] [text "Cake, please"]
        ])


cakeChoice : Model -> Either Model (Html Msg)
cakeChoice model =
    case model.interview.cakeType of
        Just c -> Left model
        Nothing -> Right (
            div [] 
                [ input [placeholder "cake type?", value model.currentCakeType, onInput UpdateCakeType ] [text "cake type?"]
                , button [onClick SaveCakeType] [text "Continue"]    
                ])

finish : Either Model (Html Msg) -> Html Msg
finish modelOrView = case modelOrView of
    Left model -> div [] [text "done"]
    Right v -> v
-- todo - questions should be Model -> Either Model (Html Msg)
-- its really really just the Either monad.

ask : (Model -> Either Model (Html Msg)) -> Either Model (Html Msg) -> Either Model (Html Msg)
ask question modelOrView =
    case modelOrView of
        Left model -> question model
        Right html -> Right html



gatherFruits : Model -> Either Model (Html Msg)
gatherFruits model =
    case getNeedMoreFruits (model.interview.fruits) of 
        NeedMore -> Right
            (div []
                [ input [ placeholder "another fruit", value model.currentFruit, onInput UpdateCurrentFruit] []
                , button [ onClick (AddFruit NeedMore) ] [ text "Save this one and add more." ]
                , button [ onClick (AddFruit Done)] [text "Save this one and don't add any more."]
                ])
        Done -> Left model

askName : Model -> Either Model (Html Msg)
askName model =
    case model.interview.firstname of
        Nothing ->
            Right (div [] 
                [ input [ placeholder "set first name", value (Maybe.withDefault "" model.currentFirstName), onInput UpdateFirstName ] []
                , input [ placeholder "set last name", value (Maybe.withDefault "" model.currentLastName), onInput UpdateLastName] []
                , button [ onClick SaveName] [text "Save and continue."]
                ])
        _ ->  Left model


-- We need to have separate state for the things currently be entered, and the Interview data. And a 'Save' button that saves the currently-being-written thing
-- to the interview. Otherwise the app can't tell that some question hasn't really been answered, the moment you type anything into its input.

type Msg
    = UpdateFirstName String
    | SaveName
    | UpdateLastName String
    | AddFruit NeedMore
    | UpdateCurrentFruit String
    | ChooseDeath
    | ChooseCake
    | UpdateCakeType String
    | SaveCakeType 

update : Msg -> Model -> Model
update msg model = 
    let 
        interview = model.interview 
    in
        case msg of 
            UpdateFirstName first -> { model | currentFirstName = Just first }
            UpdateLastName last -> { model | currentLastName = Just last }
            SaveName -> { model | interview = { interview | lastname = model.currentLastName, firstname = model.currentFirstName }}
            AddFruit needmore -> { model | interview = { interview | fruits = setAnyMoreFruits (addFruit model.interview.fruits model.currentFruit) needmore}, currentFruit = "" }
            UpdateCurrentFruit newFruit -> { model | currentFruit = newFruit }
            ChooseDeath -> { model | interview = { interview | cakeOrDeath = Just Death }}
            ChooseCake -> { model | interview = { interview | cakeOrDeath = Just Cake }}
            UpdateCakeType newcake -> { model | currentCakeType = newcake }
            SaveCakeType -> { model | interview = { interview | cakeType = Just model.currentCakeType } }


type alias FirstName = Maybe String
type alias LastName =  Maybe String
type alias Fruit = String
type Fruits  = Fruits (List Fruit) NeedMore

addFruit : Fruits -> String -> Fruits
addFruit (Fruits fs needmore) newF = Fruits (fs ++ [newF]) needmore


setAnyMoreFruits : Fruits -> NeedMore -> Fruits
setAnyMoreFruits (Fruits fs _) nm = Fruits fs nm

setNoMoreFruits : Fruits -> Fruits
setNoMoreFruits fs = setAnyMoreFruits fs Done 

getNeedMoreFruits : Fruits -> NeedMore

getNeedMoreFruits (Fruits _ nm) = nm

type NeedMore = NeedMore
              | Done




type CakeOrDeath = Cake 
                 | Death

type alias CakeType = String


type alias Interview =
    {
        firstname: FirstName,
        lastname: LastName,
        fruits : Fruits,
        cakeOrDeath : Maybe CakeOrDeath,
        cakeType : Maybe String
    }

type alias Model = 
    { interview: Interview
    , currentFirstName: FirstName
    , currentLastName: LastName
    , currentFruit: Fruit
    , currentCakeType: String
    }

init : Model
init = Model (Interview Nothing Nothing (Fruits [] NeedMore) Nothing Nothing) Nothing Nothing "" ""
     



displayInterview : Interview -> Html Msg
displayInterview interview = div [] 
    [ text ("-" ++ (Maybe.withDefault "?" interview.firstname) ++ "-")
    , text ("-" ++ (Maybe.withDefault "?" interview.lastname) ++ "-")
    , div [] (listFruits interview.fruits) 
    , div [] [text (Maybe.withDefault "?" interview.cakeType)]
    ]


listFruits : Fruits -> List (Html Msg)
listFruits (Fruits fruits _) =
    let showFruit f = div [] [text f]
    in
    List.map showFruit fruits



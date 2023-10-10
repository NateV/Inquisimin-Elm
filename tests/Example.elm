module Example exposing (..)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Test exposing (..)
import Test.Html.Query as Query
import DictModel exposing (..)
import Inquisimin exposing (..)
import Html exposing (Html)
import Test.Html.Selector exposing (text)

suite : Test
suite = describe "DictModel Interviews" 
    [ test "new interview presents the first question" <| 
        \_ -> 
            let 
                askfname : Model -> Interviewer (Model) (Html Msg) 
                askfname model = mkTextQuestionView "firstname"  "First Name" model
                
                -- a dictmodel question in point-free style.
                cattype : Model -> Interviewer (Model) (Html Msg)
                cattype = mkTextQuestionView "cattype" "Cat Type"
                
        
                interview m = Interview m
                    (\m_ -> m_
                     |> ask askfname
                     |> ask cattype)
                    displayDictModel 

                firstview = runInterview (interview (mkDictModel))
            in 
                Query.fromHtml firstview
                |> Query.has [text "First Name"]

    , test "interview presents the next question" <| 
        \_ -> 
            let 
                askfname : Model -> Interviewer (Model) (Html Msg) 
                askfname model = mkTextQuestionView "firstname"  "First Name" model
                
                -- a dictmodel question in point-free style.
                cattype : Model -> Interviewer (Model) (Html Msg)
                cattype = mkTextQuestionView "cattype" "Cat Type"
                
                newModel = mkDictModel
                updatedModel = updateDictModel (SaveQuestion "firstname" "Joe") newModel
        
                interview = Interview updatedModel
                    (\m_ -> m_
                     |> ask askfname
                     |> ask cattype)
                    displayDictModel
                     

                firstview = runInterview (interview)
            in 
                Query.fromHtml firstview
                |> Query.has [text "Cat Type"]
    , test "Back msg goes to the previous question" <| 
        \_ -> 
            let 
                askfname : Model -> Interviewer (Model) (Html Msg) 
                askfname model = mkTextQuestionView "firstname"  "First Name" model
                
                -- a dictmodel question in point-free style.
                cattype : Model -> Interviewer (Model) (Html Msg)
                cattype = mkTextQuestionView "cattype" "Cat Type"
                
                newModel = mkDictModel
                updatedModel = updateDictModel (SaveQuestion "firstname" "Joe") newModel
                updatedAgain = updateDictModel GoBack updatedModel


                interview = Interview updatedAgain
                    (\m_ -> m_
                     |> ask askfname
                     |> ask cattype)
                    displayDictModel
                     

                firstview = runInterview (interview)
            in 
                Query.fromHtml firstview
                |> Query.has [text "First Name"]

           
    ]

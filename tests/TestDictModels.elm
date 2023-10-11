module TestDictModels exposing (..)

{-| Test various properties of interviews built in the DictModel style of interivews. 

-}


import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Test exposing (..)
import Test.Html.Query as Query
import DictModel as DM
import Inquisimin exposing (..)
import Html exposing (Html)
import Test.Html.Selector exposing (text)

suite : Test
suite = describe "DictModel Interviews" 
    [ test "new interview presents the first question" <| 
        \_ -> 
            let 
                askfname : DM.DictModel -> Interviewer (DM.DictModel) (Html DM.Msg) 
                askfname model = DM.mkTextQuestionView "firstname"  "First Name" model
                
                -- a dictmodel question in point-free style.
                cattype : DM.DictModel -> Interviewer (DM.DictModel) (Html DM.Msg)
                cattype = DM.mkTextQuestionView "cattype" "Cat Type"
                
        
                interview m = Interview m
                    (\m_ -> m_
                     |> ask askfname
                     |> ask cattype)
                    DM.displayDictModel 

                firstview = runInterview (interview (DM.mkDictModel))
            in 
                Query.fromHtml firstview
                |> Query.has [text "First Name"]

    , test "interview presents the next question" <| 
        \_ -> 
            let 
                askfname : DM.DictModel -> Interviewer (DM.DictModel) (Html DM.Msg) 
                askfname model = DM.mkTextQuestionView "firstname"  "First Name" model
                
                -- a dictmodel question in point-free style.
                cattype : DM.DictModel -> Interviewer (DM.DictModel) (Html DM.Msg)
                cattype = DM.mkTextQuestionView "cattype" "Cat Type"
                
                newModel = DM.mkDictModel
                updatedModel = DM.updateDictModel (DM.SaveQuestion "firstname" "Joe") newModel
        
                interview = Interview updatedModel
                    (\m_ -> m_
                     |> ask askfname
                     |> ask cattype)
                    DM.displayDictModel
                     

                firstview = runInterview (interview)
            in 
                Query.fromHtml firstview
                |> Query.has [text "Cat Type"]
    , test "Back msg goes to the previous question" <| 
        \_ -> 
            let 
                askfname : DM.DictModel -> Interviewer (DM.DictModel) (Html DM.Msg) 
                askfname model = DM.mkTextQuestionView "firstname"  "First Name" model
                
                -- a dictmodel question in point-free style.
                cattype : DM.DictModel -> Interviewer (DM.DictModel) (Html DM.Msg)
                cattype = DM.mkTextQuestionView "cattype" "Cat Type"
                
                newModel = DM.mkDictModel
                updatedModel = DM.updateDictModel (DM.SaveQuestion "firstname" "Joe") newModel
                updatedAgain = DM.updateDictModel DM.GoBack updatedModel


                interview = Interview updatedAgain
                    (\m_ -> m_
                     |> ask askfname
                     |> ask cattype)
                    DM.displayDictModel
                     

                firstview = runInterview (interview)
            in 
                Query.fromHtml firstview
                |> Query.has [text "First Name"]

           
    ]

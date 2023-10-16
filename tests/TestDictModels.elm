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
                
                asklname = DM.mkTextQuestionView "lastname" "Last Name"
                -- a dictmodel question in point-free style.
                cattype : DM.DictModel -> Interviewer (DM.DictModel) (Html DM.Msg)
                cattype = DM.mkTextQuestionView "cattype" "Cat Type"
                
                newModel = DM.mkDictModel
                updatedModel = DM.updateDictModel (DM.SaveQuestion "firstname" "Joe") newModel
                updatedModel_ = DM.updateDictModel (DM.SaveQuestion "lastname" "Smith") updatedModel
                updatedAgain = DM.updateDictModel DM.GoBack updatedModel_


                interview = Interview updatedAgain
                    (\m_ -> m_
                     |> ask askfname
                     |> ask asklname
                     |> ask cattype)
                    DM.displayDictModel
                     

                firstview = runInterview (interview)
            in 
                Query.fromHtml firstview
                |> Query.has [text "Last Name"]
    , test "Back msg goes back to the last _completed_ question" <| 
         \_ -> 
            let 
                askfname : DM.DictModel -> Interviewer (DM.DictModel) (Html DM.Msg) 
                askfname model = DM.mkTextQuestionView "firstname"  "First Name" model
                
                asklname = DM.mkTextQuestionView "lastname" "Last Name"
                -- a dictmodel question in point-free style.
                cattype : DM.DictModel -> Interviewer (DM.DictModel) (Html DM.Msg)
                cattype = DM.mkTextQuestionView "cattype" "Cat Type"
                
                newModel = DM.mkDictModel
                updatedModel = DM.updateDictModel (DM.SaveQuestion "firstname" "Joe") newModel
                -- we update the next question, but don't save it. Going back should still take us to
                -- 'firstname'. 
                updatedModel_ = DM.updateDictModel (DM.UpdateQuestion "lastname" "Smith") updatedModel
                updatedAgain = DM.updateDictModel DM.GoBack updatedModel_


                interview = Interview updatedAgain
                    (\m_ -> m_
                     |> ask askfname
                     |> ask asklname
                     |> ask cattype)
                    DM.displayDictModel
                     

                firstview = runInterview (interview)
            in 
                Query.fromHtml firstview
                |> Query.has [text "First Name"]   
        , test "previous question returns the previous 'Answered' q, not Unanswered." <| 
            \_ -> 
                let 
                    mdl = DM.mkDictModel
                    mdl_ = DM.updateDictModel (DM.SaveQuestion "name" "Joe") mdl 
                    mdlFinal = DM.updateDictModel (DM.UpdateQuestion "age" "14") mdl_
                    (prevKey, prevQ) = Maybe.withDefault ("", mkq alwaysValid) <| DM.previousQuestion mdlFinal
                in 
                    Expect.equal prevKey "name"
        ]

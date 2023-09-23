module Inquisimin exposing (..)
import Html exposing (Html)

type Valid a = Valid a
             | Error String

type Interviewer a b = Continue a
                     | Ask b

{-| The type of the interview to be run. 

To create an Interview, it needs

- the model the interview uses to collect and parse data.
- An interview function, which is a chain of Interviewers.
- Some final View that should be shown at the end of the interview.

-}
type Interview model msg = Interview 
   model 
   ((Interviewer model (Html msg)) -> (Interviewer model (Html msg)))
   (Interviewer model (Html msg) -> Html msg)



runInterview : Interview model msg -> Html msg
runInterview (Interview model questions finalAnswer) = 
    Continue model
    |> questions
    |> finalAnswer


{-| Helps conduct an interview by binding together interview questins. 

If the previous step decided it wanted to present something to the user (by evaluating to an Ask (Html Msg)), `ask nextQuestion` will skip `nextQuestion` and pass along the previous `Html Msg`. Otherwise it will run `nextQuestion` to give it a chance to `Ask` something or `Continue` through the interview as well. 

-}
ask : (model -> Interviewer model (Html msg)) -> Interviewer model (Html msg) -> Interviewer model (Html msg)
ask question modelOrView = 
    case modelOrView of
        Continue model -> question model
        Ask html -> Ask html



type Question a = Answered 
                    a -- the 'real' value we're collecting.
                    String --the stored thing that a came from
                | Unanswered 
                    String 
                    (String -> Valid a) 
                    String -- an error message describing what's wrong with the current value.

getQValue : Question a -> String
getQValue q = case q of 
    Answered a orig -> orig
    Unanswered t f reason -> t

{-| Make an empty Question of type a. 

Provide a parser that tries of make an `a` out of a string, and explains why it cannot, if necessary.

You probably don't need to tell Elm what the type a is.

-}
mkq : (String -> Valid a) -> Question a
mkq f = Unanswered "" f ""

completeQuestion : Question a -> Question a
completeQuestion q = case q of 
    Unanswered txt f _ -> case f txt of 
        Valid a -> Answered a txt
        Error reason -> Unanswered txt f reason
    answeredAlready -> answeredAlready


{-| Update the txt of an Unanswered question. 

NB Trying to update the text of an Answered question does nothing. 

-}
updateQuestion : String -> Question a -> Question a
updateQuestion str q = case q of 
    Answered a txt -> Answered a txt
    Unanswered txt f err -> Unanswered str f err



alwaysValid : String -> Valid String 
alwaysValid txt = Valid txt


{-|  Try to get the typed value of a question out of its text input.
-}
getAnswer : Question a -> Maybe a
getAnswer q = case q of 
    Answered a original -> Just a
    Unanswered txt parser err -> case parser txt of 
        Valid a -> Just a
        Error reason -> Nothing


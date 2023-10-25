module TestDependencyModel exposing (..)


import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Test exposing (..)
import Test.Html.Query as Query
import DependencyModel exposing (..)
import Inquisimin exposing (..)
import Html exposing (Html)
import Test.Html.Selector exposing (text)
import Dict

suite : Test
suite = describe "DependencyModel interviews" 
    [ test "checkMissing" <| 
        \_ -> 
            let 
                model = DepModel (Dict.fromList [("a", completeQuestion << mkq <| alwaysValid)]) [] ["d"] ["a","d"]
                required = ["a","d"]
                missing = ["d"]
            in
                Expect.equal (getMissing model required) missing
    ] 
 

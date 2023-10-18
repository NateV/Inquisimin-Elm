module TestDependencyModel exposing (..)


import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Test exposing (..)
import Test.Html.Query as Query
import DependencyModel exposing (..)
import Inquisimin exposing (..)
import Html exposing (Html)
import Test.Html.Selector exposing (text)

suite : Test
suite = describe "DependencyModel interviews" 
    [ test "checkMissing" <| 
        \_ -> 
            let 
                acquired = ["a","b","c"]
                required = ["a","d"]
                missing = ["d"]
            in
                Expect.equal (getMissing acquired required) missing
    ] 
 

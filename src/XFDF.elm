module XFDF exposing (..)
--| For more easily making XFDF files


type alias XFDF =
    { href : String
    , fields : List XFDFField
    }

type XFDFField = XField String String


xfieldToString : XFDFField -> String
xfieldToString (XField fieldName value) = String.join "\n" 
    [ "<field  name=\"" ++ fieldName ++ "\">" 
    , "    <value>" ++ value ++ "<value>"
    , "</field>"
    ]

xfdfToString : XFDF -> String 
xfdfToString xfdf = String.join "\n" <|
    [ "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
    , "<xfdf xmlns=\"http://ns.adobe.com/xfdf/\">"
    , "<f href=\"" ++ xfdf.href ++ "\"/>"
    , "<fields>"
    ] ++ (List.map xfieldToString xfdf.fields) ++
    [ "</fields>"
    , "</xfdf>"
    ]


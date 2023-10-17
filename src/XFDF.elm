module XFDF exposing (
    XFDF,
    XFDFField(..),
    xfdfToString
    )
--| For more easily making XFDF files

{-| Assist with exporting data collected in a guided interiview into XDF format, for importing into a fillable pdf. 

# XFDF

XFDF is an xml format for PDF Fillable form data. We can write a guided interiew that collects data and then
downloads the data as an XFDF file. Users can import the xfdf file into a fillable pdf. 

@docs XFDF, XFDFField, xfdfToString


-}

{-| Type for describing an XFDF document. 

-}
type alias XFDF =
    { href : String
    , fields : List XFDFField
    }

{-| A single fillable field in an XFDF document.

-}
type XFDFField = XField String String


{-| xfdfToString uses this to write the `field` children in and XFDF file. 

-}
xfieldToString : XFDFField -> String
xfieldToString (XField fieldName value) = String.join "\n" 
    [ "<field  name=\"" ++ fieldName ++ "\">" 
    , "    <value>" ++ value ++ "<value>"
    , "</field>"
    ]

{-| Render an `XFDF` value to an xml string.

You might let the user download this string as a file.
    
-}
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


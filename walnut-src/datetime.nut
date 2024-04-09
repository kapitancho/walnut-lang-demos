module datetime:

Clock = :[];
InvalidDate = :[];
InvalidTime = :[];
InvalidDateAndTime = :[];

Date <: [year: Integer, month: Integer<1..12>, day: Integer<1..31>] @ InvalidDate :: {
    ?whenValueOf(#.day) is {
        31: ?whenTypeOf(#.month) is {
            type{Integer[2, 4, 6, 9, 11]}: => Error(InvalidDate[]),
            ~: null
        },
        30: ?whenTypeOf(#.month) is {
            type{Integer[2]}: => Error(InvalidDate[]),
            ~: null
        },
        29: ?whenTypeOf(#.month) is {
            type{Integer[2]}: ?whenIsTrue {
                {#.year % 4} > 0: => Error(InvalidDate[]),
                {#.year % 100} == 0: ?whenIsTrue {
                    {#.year % 400} > 0: => Error(InvalidDate[]),
                    ~: null
                },
                ~: null
            },
            ~: null
        },
        ~: null
    }
};
Time <: [hour: Integer<0..23>, minute: Integer<0..59>, second: Integer<0..59>];
DateAndTime <: [date: Date, time: Time];

Date ==> String :: [
    $.year->asString,
    $.month->asString->padLeft[length: 2, padString: '0'],
    $.day->asString->padLeft[length: 2, padString: '0']
]->combineAsString('-');

JsonValue ==> Date @ InvalidDate :: {
     ?whenTypeOf($) is {
        type{String}: $->asDate,
        type[Integer, Integer<1..12>, Integer<1..31>]: Date($),
        type[year: Integer, month: Integer<1..12>, day: Integer<1..31>]: Date($),
        ~: @InvalidDate[]
     }
};

String ==> Date @ InvalidDate :: {
     pieces = $->split('-');
     ?whenTypeOf(pieces) is {
        type[String<4>, String<2>, String<2>]: {
            dateValue = [
                year: pieces.0->asInteger,
                month: pieces.1->trimLeft('0')->asInteger,
                day: pieces.2->trimLeft('0')->asInteger
            ];
            ?whenTypeOf(dateValue) is {
                type[year: Integer, month: Integer<1..12>, day: Integer<1..31>]: Date(dateValue),
                ~: @InvalidDate[]
            }
        },
        ~: @InvalidDate[]
     }
};

Time ==> String :: [
    $.hour->asString->padLeft[length: 2, padString: '0'],
    $.minute->asString->padLeft[length: 2, padString: '0'],
    $.second->asString->padLeft[length: 2, padString: '0']
]->combineAsString(':');

JsonValue ==> Time @ InvalidTime :: {
     ?whenTypeOf($) is {
        type{String}: $->asTime,
        type[Integer<0..23>, Integer<0..59>, Integer<0..59>]: Time($),
        type[hour: Integer<0..23>, minute: Integer<0..59>, second: Integer<0..59>]: Time($),
        ~: @InvalidTime[]
     }
};

String ==> Time @ InvalidTime :: {
     pieces = $->split(':');
     ?whenTypeOf(pieces) is {
        type[String<2>, String<2>, String<2>]: {
            timeValue = [
                hour: pieces.0->trimLeft('0')->asInteger,
                minute: pieces.1->trimLeft('0')->asInteger,
                second: pieces.2->trimLeft('0')->asInteger
            ];
            ?whenTypeOf(timeValue) is {
                type[hour: Integer<0..23>, minute: Integer<0..59>, second: Integer<0..59>]: Time(timeValue),
                ~: @InvalidTime[]
            }
        },
        ~: @InvalidTime[]
     }
};

DateAndTime ==> String :: [$.date->asString, $.time->asString]->combineAsString(' ');

JsonValue ==> DateAndTime @ InvalidDate|InvalidTime|InvalidDateAndTime :: {
    ?whenTypeOf($) is {
        type{String}: $->asDateAndTime,
        type[Integer, Integer<1..12>, Integer<1..31>, Integer<0..23>, Integer<0..59>, Integer<0..59>]:
            DateAndTime[?noError(Date[$.0, $.1, $.2]), ?noError(Time[$.3, $.4, $.5])],
        type[
            year: Integer,
            month: Integer<1..12>,
            day: Integer<1..31>,
            hour: Integer<0..23>,
            minute: Integer<0..59>,
            second: Integer<0..59>
        ]: DateAndTime[?noError(Date[$.year, $.month, $.day]), ?noError(Time[$.hour, $.minute, $.second])],
        type[
            date: [year: Integer, month: Integer<1..12>, day: Integer<1..31>],
            time: [hour: Integer<0..23>, minute: Integer<0..59>, second: Integer<0..59>]
        ]: DateAndTime[?noError(Date[$.date.year, $.date.month, $.date.day]), ?noError(Time[$.time.hour, $.time.minute, $.time.second])],
        ~: @InvalidDateAndTime[]
     }

};

String ==> DateAndTime @ InvalidDate|InvalidTime|InvalidDateAndTime :: {
     pieces = $->split(' ');
     ?whenTypeOf(pieces) is {
        type[String<10>, String<8>]: DateAndTime[date: pieces.0 => asDate, time: pieces.1 => asTime],
        ~: @InvalidDateAndTime[]
     }
};
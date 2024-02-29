module demo-type:

negate = ^Integer => Real :: #->unaryMinus;
LengthType = ^String => Integer;

reflectType = ^Type<Type> => Type :: #->refType;
reflectArray = ^Type<Array> => [Type, Integer<0..>, (Integer<0..>|PlusInfinity)] :: [#->itemType, #->minLength, #->maxLength];
reflectMap = ^Type<Map> => [Type, Integer<0..>, (Integer<0..>|PlusInfinity)] :: [#->itemType, #->minLength, #->maxLength];
reflectString = ^Type<String> => [Integer<0..>, (Integer<0..>|PlusInfinity)] :: [#->minLength, #->maxLength];
reflectInteger = ^Type<Integer> => [Integer|MinusInfinity, Integer|PlusInfinity] :: [#->minValue, #->maxValue];
reflectReal = ^Type<Real> => [Real|MinusInfinity, Real|PlusInfinity] :: [#->minValue, #->maxValue];
reflectMutable = ^Type<Mutable> => Type :: #->valueType;
reflectResult = ^Type<Result> => [Type, Type] :: [#->returnType, #->errorType];

reflectFunction = ^Type<^Nothing => Any> => [Type, Type] :: [#->parameterType, #->returnType];

Z1 = String<10..30>;
Z2 = Array<String, 5..100>;
Z3 = Map<String<1..10>, 5..100>;
Z4 = Integer<10..30>;
Z5 = Real<3.14..5.13>;

myFn = ^Array<String> => Any :: {
    [
        reflectString(type{Z1}),
        reflectString(type{String}),
        reflectArray(type{Z2}),
        reflectArray(type{Array}),
        reflectMap(type{Z3}),
        reflectMap(type{Map}),
        reflectInteger(type{Z4}),
        reflectInteger(type{Integer}),
        reflectReal(type{Z5}),
        reflectReal(type{Real}),
        reflectFunction(negate->type),
        reflectFunction(type{LengthType}),
        reflectMutable(type{Mutable<String>}),
        reflectResult(type{Result<String, Integer>})
    ]
};

main = ^Array<String> => String :: {
    x = myFn(#);
    x->printed
};
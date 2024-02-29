module cast23 %% db:

Point <: [x: Real, y: Real];
PositiveInteger = Integer<1..>;
Suit = :[Spades, Hearts, Diamonds, Clubs];
pi = 3.1415927;

suit = ^String => Result<Suit, UnknownEnumerationValue> :: {
    type{Suit}->valueWithName(#)
};

InvalidProductId = $[productId: Integer];
ProductId = Integer<1..>;

InvalidProductName = $[productName: String];
ProductName = String<1..>;
Product <: [~ProductId, ~ProductName];
Point ==> String :: ''->concatList['{', {$.x}->asString, ',', {$.y}->asString, '}'];

Product ==> Map :: {
    [productId: $.productId, productName: $.productName]
};

getData = ^DatabaseConnector => Result<Array<Map<String|Integer|Null>>, MapItemNotFound|CastNotAvailable|DatabaseQueryFailure> :: {
    data = ?noError(#->query[query: 'SELECT id, name FROM cast4 limit 3', boundParameters: []]);
    data->map(mapToProduct)
};

mapToProduct = ^Map => Result<Product, MapItemNotFound|CastNotAvailable> :: {
    Product[
        ?noError(?noError(#->item('id'))->as(type{ProductId})),
        ?noError(?noError(#->item('name'))->as(type{ProductName}))
    ]
};

getDataX = ^DatabaseConnector => Result<Array<Product>, MapItemNotFound|CastNotAvailable|DatabaseQueryFailure> :: {
    data = ?noError(#->query[query: 'SELECT id, name FROM cast4 limit 3', boundParameters: []]);
    data->map(mapToProductX)
};

mapToProductX = ^Map => Result<Product, MapItemNotFound|CastNotAvailable|DatabaseQueryFailure> :: {
    #->as(type{Product})
};

getDataY = ^[~DatabaseConnector, targetType: Type] => Result<Array, MapItemNotFound|CastNotAvailable|DatabaseQueryFailure> :: {
    data = ?noError(#.databaseConnector->query[query: 'SELECT id, name FROM cast4 limit 3', boundParameters: []]);
    data->map(mapToProductY[#.targetType])
};

MapX = ^Map => Result<Any, MapItemNotFound|CastNotAvailable|DatabaseQueryFailure>;

mapToProductY = ^[targetType: Type] => MapX :: {
    targetType = #.targetType;
    ^Map => Result<Any, MapItemNotFound|CastNotAvailable|DatabaseQueryFailure> :: {
        #->as(targetType)
    }
};

ProductArray = Array<Product>;

getDataZ = ^[~DatabaseConnector] => Result<Array, MapItemNotFound|CastNotAvailable|DatabaseQueryFailure> :: {
    c = getDataY[#.databaseConnector, type{Product}];
    c->as(type{ProductArray})
};

getRow = ^DatabaseConnector => Result<Map<String|Integer|Null>, IndexOutOfRange|MapItemNotFound|CastNotAvailable|DatabaseQueryFailure> :: {
    data = ?noError(#->query[query: 'SELECT id, name FROM cast4 limit 3', boundParameters: []]);
    row = ?noError(data->item(0));
    mapToProduct(row)
};

getRowE = ^DatabaseConnector => Result<Map<String|Integer|Null>, IndexOutOfRange|MapItemNotFound|CastNotAvailable|DatabaseQueryFailure> :: {
    data = ?noError(#->query[query: 'SELECT id, name FOM cast4 limit 3', boundParameters: []]);
    row = ?noError(data->item(0));
    mapToProduct(row)
};

==> DatabaseConnection :: DatabaseConnection['sqlite:db.sqlite'];

myFn = ^Array<Any> => Any :: {
    /*Point[pi, 42]->as(type{String});*/
    connection = DatabaseConnection['sqlite:db.sqlite'];
    connector = DatabaseConnector[connection];
    [
        suit('Spades'),
        suit('King'),
        getData(connector),
        getDataX(connector),
        getDataY[connector, type{Product}],
        getDataZ[connector],
        getRow(connector),
        getRowE(connector)
    ]
};
Any ==> ProductName @ InvalidProductName|CastNotAvailable :: {
    x = ?noError($->as(type{String}));
    ?whenTypeOf(x) is { type{ProductName}: x, ~: Error(InvalidProductName[x]) }
};
Map ==> Product @ MapItemNotFound|InvalidProductName|CastNotAvailable :: {
    Product[
        ?noError(?noError($->item('id'))->as(type{ProductId})),
        ?noError(?noError($->item('name'))->as(type{ProductName}))
    ]
};
main = ^Array<String> => String :: {
    x = myFn(#);
    x->printed
};
module db:

DatabaseConnection <: [dsn: String];
DatabaseConnector = $[connection: DatabaseConnection];

DatabaseValue = String|Integer|Boolean|Null;
DatabaseQueryBoundParameters = Array<DatabaseValue>|Map<DatabaseValue>;
DatabaseQueryCommand = [query: String<1..>, boundParameters: DatabaseQueryBoundParameters];
DatabaseQueryResultRow = Map<DatabaseValue>;
DatabaseQueryResult = Array<DatabaseQueryResultRow>;
DatabaseQueryFailure = $[query: String<1..>, boundParameters: DatabaseQueryBoundParameters, error: String];
DatabaseQueryFailure->error(^Null => String) :: $.error;

DatabaseQueryFailure ==> ExternalError :: ExternalError[
    errorType: $->type->typeName,
    originalError: $,
    errorMessage: $.error
];

==> DatabaseConnector %% DatabaseConnection :: DatabaseConnector[connection: %];

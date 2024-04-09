module demo-task-json-file %% demo-task-repository, fs:

JsonFileTaskList = $[jsonStorage: File];
JsonFileTaskList->retrieve(^Null => Result<Map<TaskStorageData>, ExternalError>) :: {
    retriever = ^Null => Result<Map<TaskStorageData>, HydrationError|InvalidJsonString|CannotReadFile> ::
        $.jsonStorage=>content => jsonDecode => hydrateAs(type{Map<TaskStorageData>});
    result = retriever();
    ?whenTypeOf(result) is {
        type{Map<TaskStorageData>}: result,
        type{Error}: @ExternalError[errorType: result->type->printed, originalError: result, errorMessage: 'error']
    }
};
JsonFileTaskList->persist(^Map<TaskStorageData> => Result<Map<TaskStorageData>, ExternalError>) :: {
    persister = ^Map<TaskStorageData> => Result<Map<TaskStorageData>, CannotWriteFile|InvalidJsonValue> :: {
        $.jsonStorage=>replaceContent(#=>jsonStringify);
        #
    };
    result = persister(#);
    ?whenTypeOf(result) is {
        type{Map<TaskStorageData>}: result,
        type{Error}: @ExternalError[errorType: result->type->printed, originalError: result, errorMessage: 'error']
    }
};

==> TaskRetrieveAll  %% [~JsonFileTaskList] :: ^Null => Result<Array<TaskStorageData>, ExternalError> ::
    %.jsonFileTaskList=>retrieve->values;
==> TaskRetrieveById %% [~JsonFileTaskList] :: ^String<36> => Result<TaskStorageData, UnknownTask|ExternalError> :: {
    result = %.jsonFileTaskList=>retrieve->item(#);
    ?whenTypeOf(result) is {
        type{TaskStorageData}: result,
        type{Error<MapItemNotFound>}: @UnknownTask[]
    }
};
==> TaskPersist      %% [~JsonFileTaskList] :: ^TaskStorageData => Result<TaskStorageSuccessful, ExternalError> :: {
    %.jsonFileTaskList=>persist(%.jsonFileTaskList=>retrieve->withKeyValue[key: #.id, value: #]);
    TaskStorageSuccessful[]
};
==> TaskRemoveById   %% [~JsonFileTaskList] :: ^String<36> => Result<TaskStorageSuccessful, UnknownTask|ExternalError> :: {
    result = %.jsonFileTaskList=>retrieve->withoutByKey(#);
    ?whenTypeOf(result) is {
        type[element: TaskStorageData, map: Map<TaskStorageData>]: {
            %.jsonFileTaskList=>persist(result.map);
            TaskStorageSuccessful[]
        },
        ~: @UnknownTask[]
    }
};
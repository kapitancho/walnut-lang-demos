module demo-task-repository:

TaskStorageSuccessful = :[];
UnknownTask = :[];
TaskStorageData = [
    id: String<36>,
    title: String<1..>,
    isDone: Boolean,
    dueDate: String<10>,
    createdAt: String<19>,
    description: String
];

TaskPersist = ^TaskStorageData => Result<TaskStorageSuccessful, ExternalError>;
TaskRetrieveAll = ^Null => Result<Array<TaskStorageData>, ExternalError>;
TaskRetrieveById = ^String<36> => Result<TaskStorageData, UnknownTask|ExternalError>;
TaskRemoveById = ^String<36> => Result<TaskStorageSuccessful, UnknownTask|ExternalError>;

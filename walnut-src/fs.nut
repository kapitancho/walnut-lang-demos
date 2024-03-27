module fs:

File = $[path: String];
File->path(^Null => String) :: $.path;

CannotReadFile = $[file: File];
CannotReadFile->file(^Null => File) :: $.file;
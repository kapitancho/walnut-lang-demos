module demo-r:

A = ['$ref\`\\': String];
a = ['$ref\`\\': ''];
B1 = [a: String, b: ?String];
B2 = [a: String, b: OptionalKey<String>];

main = ^Array<String> => String :: [
    a->isOfType(type{A}),
    type{B1}->isSubtypeOf(type{B2}),
    type{B2}->isSubtypeOf(type{B1})
]->printed;
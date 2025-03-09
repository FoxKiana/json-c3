module json;

// Deserialize basic types from json
// - number
// - string
// - array
// - struct
// - null?

// zero copy, only allocates for slices (json arrays)
macro from_str($Type, Allocator alloc, String s) {
	Lexer lex;
	lex.init(s);
	return deserialize::parse($Type, alloc, &lex);
}

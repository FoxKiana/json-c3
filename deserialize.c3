module json::deserialize;
import std::collections;
import std::core;
import std::io;
import json::lex;

macro parse($Type, Allocator alloc, Lexer* lex) {
	$if ($defined($Type.parse_json)):
		$Type custom;
		// NOTE if just rethrowing, macro doesn't seem to realize
		// that the return type is $TYPE!
		if (catch custom.parse_json(alloc, lex)) {
			return ParseResult.ERROR?;
		}
		return custom;
	$endif

	Tag first_tag = lex.next()!!;
	// hack for array end, see below.
	if (first_tag == ARRAY_END) return ParseResult.ARRAY_END?;

	// Switch on primitives
	$switch ($Type)
		$case String:
			switch(first_tag) {
				case STRING: return lex.token_slice;
				default: return ParseResult.ERROR?;
			}
		$case bool:
			switch(first_tag) {
				case TRUE: return true;
				case FALSE: return false;
				default: return ParseResult.ERROR?;
			}
		$case int:
			switch(first_tag) {
				case NUM: return ((String)lex.token_slice).to_int(10);
				default: return ParseResult.ERROR?;
			}
	$endswitch

	// Switch on complex types
	$switch ($Type.kindof)
		$case TypeKind.STRUCT:
			$Type obj;
			if (first_tag != OBJ_START) return ParseResult.ERROR?;
			// iterate through each parsed field, do linear search against
			//members of struct.
			while (true) {
				Tag tag = lex.next()!!;
				if (tag == OBJ_END) break;
				if (tag != FIELD_NAME) return ParseResult.ERROR?;
				String field_name = (String)lex.token_slice;
				$foreach ($member : $Type.membersof)
					if (field_name == $member.nameof) {
						obj.$eval($member.nameof) = parse($typefrom($member.typeid), alloc, lex)!!;
						// break; no break in compile-time foreach?
					}
				$endforeach
			}
			return obj;
		$case TypeKind.SLICE:
			if (first_tag != ARRAY_START) return ParseResult.ERROR?;
			@pool(alloc) {
				List(<$typefrom($Type.inner)>) arr;
				arr.temp_init();

				while (true) {
					var value = parse($typefrom($Type.inner), alloc, lex);
					if (catch err = value) {
						// This is a hacky way to catch the end of the array.
						// But checking the tag will advance one. FIX
						if (err == ParseResult.ARRAY_END) break;
						return ParseResult.ERROR?;
					}
					arr.push(value);
				}
				return arr.to_new_array(alloc);
			};
	$endswitch

	return ParseResult.ERROR?;
}

fault ParseResult {
	ERROR,
	ARRAY_END, // TODO fix this hack
}

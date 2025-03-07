module json;
import std::collections;
import std::core;
import std::io;
import lex;

// Deserialize basic types from json
// - number
// - string
// - array
// - struct
// - null?
//
// In the future, could do custom serialization by method on type.
// But currently can't as static/constructor methods not allowed. Check
// how odin handles 

// zero copy, only allocates for slices (json arrays)
macro from_str($Type, Allocator alloc, String s) {
	Lexer lex;
	lex.init(s);
	return parse($Type, alloc, &lex);
}

macro parse($Type, Allocator alloc, Lexer* lex) {
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

fn void test_basic() @test {
	test::eq(from_str(bool, allocator::temp(), "true")!!, true);
	test::eq(from_str(String, allocator::temp(), "\"foo\"")!!, "foo");
	test::eq(from_str(int, allocator::temp(), "1")!!, 1);
}

// === Tests ===

struct Foo {
	bool is_bar;
	int baz;
}

fn bool Foo.equals(self, Foo other) {
	return self.is_bar == other.is_bar && self.baz == other.baz;
}

fn void test_struct() @test {
	Foo foo = from_str(Foo, allocator::temp(), "{ \"is_bar\": true, \"baz\": 3 }")!!;
	test::eq(foo, Foo { .is_bar = true, .baz = 3 });
}

fn void test_array() @test {
	test::eq(from_str(int[], allocator::temp(), "[ 1, 2 ]")!!, int[] { 1, 2 });
}

struct Bar {
	int[] bar;
}
fn void test_soa() @test {
	Bar bar = from_str(Bar, allocator::temp(), "{ \"bar\": [ 1, 2 ]}")!!;
	test::eq(bar.bar, int[] { 1, 2, });
}

fn void test_aos() @test {
	Foo[] foos= from_str(Foo[], allocator::temp(), `[{"is_bar":true},{"is_bar":false}]`)!!;
	// Foo[] doesn't implement equatable even when Foo does?
	test::eq(foos[0], Foo { .is_bar = true });
	test::eq(foos[1], Foo { .is_bar = false });
}

fault ParseResult {
	ERROR,
	ARRAY_END, // TODO fix this hack
}

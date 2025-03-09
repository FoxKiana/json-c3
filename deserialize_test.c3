module deserialize_test;
import json;

fn void test_basic() @test {
	test::eq(json::from_str(bool, allocator::temp(), "true")!!, true);
	test::eq(json::from_str(String, allocator::temp(), "\"foo\"")!!, "foo");
	test::eq(json::from_str(int, allocator::temp(), "1")!!, 1);
}

struct Foo {
	bool is_bar;
	int baz;
}

fn bool Foo.equals(self, Foo other) {
	return self.is_bar == other.is_bar && self.baz == other.baz;
}

fn void test_struct() @test {
	Foo foo = json::from_str(Foo, allocator::temp(), "{ \"is_bar\": true, \"baz\": 3 }")!!;
	test::eq(foo, Foo { .is_bar = true, .baz = 3 });
}

fn void test_array() @test {
	test::eq(json::from_str(int[], allocator::temp(), "[ 1, 2 ]")!!, int[] { 1, 2 });
}

struct Bar {
	int[] bar;
}
fn void test_soa() @test {
	Bar bar = json::from_str(Bar, allocator::temp(), "{ \"bar\": [ 1, 2 ]}")!!;
	test::eq(bar.bar, int[] { 1, 2, });
}

fn void test_aos() @test {
	Foo[] foos= json::from_str(Foo[], allocator::temp(), `[{"is_bar":true},{"is_bar":false}]`)!!;
	// Foo[] doesn't implement equatable even when Foo does?
	test::eq(foos[0], Foo { .is_bar = true });
	test::eq(foos[1], Foo { .is_bar = false });
}

enum Baz {
	ONE,
	TWO,
}

fn void! Baz.parse_json(&self, Allocator alloc, Lexer* lex) {
	switch (lex.next()!!) {
		case STRING:
			switch (lex.token_slice) {
				case "one": *self = Baz.ONE;
				case "two": *self = Baz.TWO;
			}
		default:
			return ParseResult.ERROR?;
	}
}

fn void test_custom() @test {
	Baz baz = json::from_str(Baz, allocator::temp(), `"one"`)!!;
	test::eq(baz, Baz.ONE);
}


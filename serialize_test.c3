module serialize_test;
import std::collections;
import std::core::test;
import json;

fn void test_basic() @test {
	test::eq(json::to_json(true, allocator::temp()), "true");
	test::eq(json::to_json("one", allocator::temp()), `"one"`);
	test::eq(json::to_json(1, allocator::temp()), "1");
}

struct Foo {
	bool is_bar;
	int baz;
}

fn void test_struct() @test {
	Foo foo = { .is_bar = true, .baz = 1 };
	test::eq(json::to_json(foo, allocator::temp()), `{"is_bar":true,"baz":1}`);
}

fn void test_array() @test {
	int[] xs = { 1, 2 };
	test::eq(json::to_json(xs, allocator::temp()), "[1,2]");
}

struct Bar {
	int[] bar;
}
fn void test_soa() @test {
	Bar bar = { .bar = { 1, 2 } };
	test::eq(json::to_json(bar, allocator::temp()), `{"bar":[1,2]}`);
}

fn void test_aos() @test {
	Foo[] foos = { { .is_bar = true, .baz = 1 }, { .is_bar = false, .baz = 2 } };
	String expected = `[{"is_bar":true,"baz":1},{"is_bar":false,"baz":2}]`;
	test::eq(json::to_json(foos, allocator::temp()), expected);
}

fn void test_maybe() @test {
	Maybe{int} x = maybe::value{int}(1);
	test::eq(json::to_json(x, allocator::temp()), "1");
}

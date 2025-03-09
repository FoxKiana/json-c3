module json::serialize;
import std::core;

// TODO handle "empty" fields.
// - empty lists
// - Maybe type?

// TODO handle custom serialization

macro void add_json(src, DString* dest) {
	// Switch on primitives
	$switch ($typeof(src))
		$case String:
			dest.append(`"`);
			dest.append(src);
			dest.append(`"`);
			return;
		$case bool:
			if (src) {
				dest.append("true");
			} else {
				dest.append("false");
			}
			return;
		$case int:
			dest.appendf("%d", src);
			return;
	$endswitch

	// Switch on complex types
	$switch ($typeof(src).kindof)
		$case TypeKind.STRUCT:
			dest.append("{");
			$foreach ($idx, $member : $typeof(src).membersof)
				if ($idx > 0) {
					dest.append(",");
				}
				dest.appendf(`"%s":`, $member.nameof);
				add_json(src.$eval($member.nameof), dest);
			$endforeach
			dest.append("}");
			return;
		$case TypeKind.SLICE:
			dest.append("[");
			foreach (idx, element : src) {
				if (idx > 0) {
					dest.append(",");
				}
				add_json(element, dest);
			}
			dest.append("]");
			return;
	$endswitch

	// TODO add error here if type not supported?
}

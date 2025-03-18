module json::serialize;
import std::core;
import std::io;

// TODO handle "empty" fields.
// - empty lists
// - Maybe type?

// TODO handle custom serialization

macro void? add_json(src, DString* dest) {
	$if ($defined($typeof(src).to_json)):
		src.to_json(dest)!;
		return;
	$endif

	// Switch on primitives
	$switch ($typeof(src)):
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
	$switch ($typeof(src).kindof):
		$case TypeKind.ENUM:
			$if ($defined($typeof(src).json_repr)):
				dest.appendf(src.json_repr);
			$else
				dest.appendf(src.nameof);
			$endif
		$case TypeKind.STRUCT:
			// Check Maybe first
			$if ($typeof(src).nameof == "Maybe"):
				if (src.has_value) {
					add_json(src.$eval($typeof(src).membersof[0].nameof), dest)!!;
				} else {
					dest.appendf("null");
				}
				return;
			$endif

			// Not Maybe, just regular struct
			dest.append("{");
			int members_written;
			$foreach $member : $typeof(src).membersof:
				$if ($member.kindof == TypeKind.UNION):
					return UNION_NOT_SUPPORTED?;
				$else
					// check for @tag("json", "skip_empty")
					bool $memb_is_maybe_skip = false;
					$if ($typefrom($member.typeid).nameof == "Maybe"):
						$if ($member.has_tagof("json")):
							$if ($member.tagof("json") == "skip_empty"):
								$memb_is_maybe_skip = true;
							$endif
						$endif
					$endif

					// TODO clean up this logic. compile time and runtime interaction is a bit messy
					$if ($memb_is_maybe_skip):
						if (!src.$eval($member.nameof).has_value) {
						// do nothing
						} else {
							if (members_written > 0) {
								dest.append(",");
							}
							dest.appendf(`"%s":`, $member.nameof);
							add_json(src.$eval($member.nameof), dest)!!;
							members_written += 1;
						}
					$else
						if (members_written > 0) {
							dest.append(",");
						}
						dest.appendf(`"%s":`, $member.nameof);
						add_json(src.$eval($member.nameof), dest)!!;
						members_written += 1;
					$endif
				$endif
			$endforeach
			dest.append("}");
			return;
		$case TypeKind.SLICE:
			dest.append("[");
			foreach (idx, element : src) {
				if (idx > 0) {
					dest.append(",");
				}
				add_json(element, dest)!!;
			}
			dest.append("]");
			return;
		$case TypeKind.UNION:
			return UNION_NOT_SUPPORTED?;
	$endswitch

	// TODO add error here if type not supported?
}

faultdef UNION_NOT_SUPPORTED;

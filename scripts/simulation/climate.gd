class_name Climate
extends RefCounted

enum Type { STABLE, RAIN, FROST, CATASTROPHE }

const EVENTS: Array[int] = [Type.STABLE, Type.RAIN, Type.FROST, Type.CATASTROPHE]

const LABELS := {
	Type.STABLE: "Estable",
	Type.RAIN: "Lluvia",
	Type.FROST: "Helada",
	Type.CATASTROPHE: "Catástrofe",
}


static func label(type: Type) -> String:
	return LABELS[type]

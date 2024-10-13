package hscript.macros;

#if macro
import haxe.macro.Type.ClassType;
import Type.ValueType;
import haxe.macro.Expr.Function;
import haxe.macro.Expr;
import haxe.macro.Type.MetaAccess;
import haxe.macro.Type.FieldKind;
import haxe.macro.Type.ClassField;
import haxe.macro.Type.VarAccess;
import haxe.macro.*;

using StringTools;

class Utils {
	public static function fixStdTypes(type:ComplexType) {
		switch(type) {
			case TPath({name: "StdTypes"}):
				var a:TypePath = type.getParameters()[0];
				a.name = a.sub;
				a.sub = null;
			default:
		}
		return type;
	}

	public static function setupMetas(shadowClass:TypeDefinition, imports) {
		if (shadowClass.meta == null) shadowClass.meta = [];
		shadowClass.meta = shadowClass.meta.concat([
							{name: ":dox", params: [macro hide], pos: Context.currentPos()},
							{name: ":noCompletion", params: [], pos: Context.currentPos()}
						]);
		var module = Context.getModule(Context.getLocalModule());
		for(t in module) {
			switch(t) {
				case TInst(t, params):
					if (t != null) {
						var e = t.get();
						processModule(shadowClass, e.module, e.name);
						processImport(imports, e.module, e.name);
					}
				case TEnum(t, params):
					if (t != null) {
						var e = t.get();
						processModule(shadowClass, e.module, e.name);
						processImport(imports, e.module, e.name);
					}
				case TType(t, params):
					if (t != null) {
						var e = t.get();
						processModule(shadowClass, e.module, e.name);
						processImport(imports, e.module, e.name);
					}
				case TAbstract(t, params):
					if (t != null) {
						var e = t.get();
						processModule(shadowClass, e.module, e.name);
						processImport(imports, e.module, e.name);
					}
				default:
					// not needed?
			}
		}
	}

	public static function processModule(shadowClass:TypeDefinition, module:String, n:String) {
		n = removeImpl(n);
		module = removeImpl(module);

		shadowClass.meta.push(
			{
				name: ':access',
				params: [
					Context.parse(fixModuleName(module.endsWith('.$n') ? module : '${module}.${n}'), Context.currentPos())
				],
				pos: Context.currentPos()
			}
		);
	}


	/*public static function getModuleName(path:Type) {
		switch(path) {
			case TPath(name, pack):// | TDClass(name, pack):
				var str = "";
				for(p in pack) {
					str += p + ".";
				}
				str += name;
				return str;

			default:
		}
		return "INVALID";
	}*/

	public static function fixModuleName(name:String) {
		return name;
		// var split = name.split(".");
		// if (split.length > 1 && split[split.length - 2].charAt(0) == "_")
		// 	split[split.length - 2] = split[split.length - 2].substr(1);
		// return split.join(".");
	}

	public static function removeImpl(name:String) {
		if (name.endsWith("_Impl_"))
			name = name.substr(0, name.length - 6);
		return name;
	}

	public static function processImport(imports:Array<ImportExpr>, module:String, n:String) {
		n = removeImpl(n);
		module = fixModuleName(module);
		module = removeImpl(module);

		imports.push({
			path: [for(m in module.split(".")) {
				name: m,
				pos: Context.currentPos()
			}],
			mode: INormal
		});
	}

	public static function cleanExpr(expr:Expr, oldFunc:String, newFunc:String) {
		if (expr == null) return;
		if (expr.expr == null) return;
		switch(expr.expr) {
			case EConst(c):
				switch(c) {
					case CIdent(s):
						if (s == oldFunc)
							expr.expr = EConst(CIdent(newFunc));
					case CString(s, b):
						if (s == oldFunc)
							expr.expr = EConst(CString(s, b));
					default:
						// nothing
				}
			case EField(e, field):
				if (field == oldFunc && e != null) {
					switch(e.expr) {
						case EConst(c):
							switch(c) {
								case CIdent(s):
									if (s == "super")
										expr.expr = EField(e, newFunc);
								default:

							}
						default:

					}
				}
			case EParenthesis(e):
				cleanExpr(e, oldFunc, newFunc);
			case EObjectDecl(fields):
				for(f in fields) {
					cleanExpr(f.expr, oldFunc, newFunc);
				}
			case EArrayDecl(values):
				for(a in values) {
					cleanExpr(a, oldFunc, newFunc);
				}
			case ECall(e, params):
				cleanExpr(e, oldFunc, newFunc);
			case EBlock(exprs):
				for(e in exprs)
					cleanExpr(e, oldFunc, newFunc);
			case EFor(it, expr):
				cleanExpr(it, oldFunc, newFunc);
				cleanExpr(expr, oldFunc, newFunc);
			case EIf(econd, eif, eelse):
				cleanExpr(econd, oldFunc, newFunc);
				cleanExpr(eif, oldFunc, newFunc);
				cleanExpr(eelse, oldFunc, newFunc);
			case EWhile(econd, e, normalWhile):
				cleanExpr(econd, oldFunc, newFunc);
				cleanExpr(e, oldFunc, newFunc);
			case ECast(e, t):
				cleanExpr(e, oldFunc, newFunc);
			case ECheckType(e, t):
				cleanExpr(e, oldFunc, newFunc);
			case ETry(e, catches):
				cleanExpr(e, oldFunc, newFunc);
				for(c in catches) {
					cleanExpr(c.expr, oldFunc, newFunc);
				}
			case EThrow(e):
				cleanExpr(e, oldFunc, newFunc);
			case ETernary(econd, eif, eelse):
				cleanExpr(econd, oldFunc, newFunc);
				cleanExpr(eif, oldFunc, newFunc);
				cleanExpr(eelse, oldFunc, newFunc);
			case ESwitch(e, cases, edef):
				cleanExpr(e, oldFunc, newFunc);
				for(c in cases) {
					cleanExpr(c.expr, oldFunc, newFunc);
				}
				cleanExpr(edef, oldFunc, newFunc);
			case EReturn(e):
				cleanExpr(e, oldFunc, newFunc);
			case EIs(e, t):
				cleanExpr(e, oldFunc, newFunc);
			case EVars(vars):
				for(v in vars) {
					cleanExpr(v.expr, oldFunc, newFunc);
				}
			case ENew(t, params):
				for(p in params) {
					cleanExpr(p, oldFunc, newFunc);
				}
			default:
		}
	}
}
#end
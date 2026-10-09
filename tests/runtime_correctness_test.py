"""Runtime correctness and native/Python parity regression checks."""
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

GZIM = str(Path(sys.argv.pop(1)).resolve())


class RuntimeCorrectnessTests(unittest.TestCase):
    def run_code(self, code):
        return subprocess.run([GZIM, 'eval', code], capture_output=True, text=True, timeout=15)

    def parity(self, code, expected):
        result = self.run_code(code)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, expected)
        with tempfile.TemporaryDirectory() as tmp:
            source = Path(tmp) / 'case.gzim'
            source.write_text(code, encoding='utf-8')
            converted = subprocess.run([GZIM, 'convert', str(source), '--to', 'py'], capture_output=True, text=True)
            self.assertEqual(converted.returncode, 0, converted.stderr)
            exported = subprocess.run([sys.executable, str(source.with_suffix('.py'))], capture_output=True, text=True, timeout=15)
            self.assertEqual(exported.returncode, 0, exported.stderr)
            self.assertEqual(exported.stdout, expected)

    def test_integer_precision_and_mixed_comparisons(self):
        self.parity('''yap(9007199254740992 == 9007199254740993)
yap(9007199254740993 > 9007199254740992)
yap(9007199254740993 == 9007199254740992.0)
yap(9007199254740993 > 9007199254740992.0)
yap(9223372036854775807 < 9223372036854775808.0)
yap(9007199254740993 // 1, 9007199254740993 % 2)
yap(-7 // 3, -7 % 3, 7 // -3, 7 % -3)
yap(-7 // -3, -7 % -3)
yap(1 < 1.5, 1.5 > 1, -1 > -1.5, -1.5 < -1)
yap(nocap == 1, cap == 0)
''', 'False\nTrue\nFalse\nTrue\nTrue\n9007199254740993 1\n-3 2 -3 -2\n2 -1\nTrue True True True\nTrue True\n')

    def test_nonfinite_comparisons(self):
        self.parity('''let n be drip("nan")
yap(n == 1, n < 1, n <= 1, 1 >= n)
yap(drip("inf") > 9223372036854775807)''', 'False False False False\nTrue\n')

    def test_int64_boundary(self):
        result = self.run_code('''let low be -9223372036854775807 - 1
yap(low % -1)
f_around:
    yap(low // -1)
find_out BadVibe:
    yap("overflow caught")''')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, '0\noverflow caught\n')

    def test_set_equality_and_distinct_large_values(self):
        self.parity('''yap({1, 2} == {2, 1})
yap({1, 2} == {1, 3})
yap([1, 2] == [2, 1])
yap(call up how many({9007199254740992, 9007199254740993}) yo)
''', 'True\nFalse\nFalse\n2\n')

    def test_finally_on_unhandled_and_handler_errors(self):
        for body in ['throw shade BadVibe("first")', 'throw shade WrongType("first")\n    find_out WrongType:\n        throw shade BadVibe("second")']:
            code = 'f_around:\n    f_around:\n        ' + body + '\n    no_matter_what:\n        yap("cleanup")\nfind_out BadVibe:\n    yap("caught")'
            self.parity(code, 'cleanup\ncaught\n')

    def test_finally_overrides_return_and_exception(self):
        self.parity('''cook answer():
    f_around:
        throw shade BadVibe("oops")
    no_matter_what:
        send it 42
cook other():
    f_around:
        send it 1
    no_matter_what:
        send it 2
yap(answer(), other())
''', '42 2\n')

    def test_nested_handlers_restore_active_exception(self):
        self.parity('''f_around:
    f_around:
        throw shade BadVibe("outer")
    find_out BadVibe:
        f_around:
            throw shade WrongType("inner")
        find_out WrongType:
            yap("inner caught")
        throw shade
find_out BadVibe:
    yap("outer caught")
''', 'inner caught\nouter caught\n')

    def test_finally_on_else_error_and_loop_control(self):
        self.parity('f_around:\n    f_around:\n        yap("body")\n    find_out BadVibe:\n        deadass\n    otherwise:\n        throw shade BadVibe("else")\n    no_matter_what:\n        yap("cleanup")\nfind_out BadVibe:\n    yap("caught")\nfor real i up in vibes(2):\n    f_around:\n        next\n    no_matter_what:\n        yap(i)\nf_around:\n    f_around:\n        throw shade BadVibe("first")\n    no_matter_what:\n        throw shade WrongType("replacement")\nfind_out WrongType:\n    yap("replacement caught")\n', 'body\ncleanup\ncaught\n0\n1\nreplacement caught\n')

    def test_ancestor_keywords(self):
        self.parity('clique Base:\n    cook new(fam, value):\n        fam.value be value\nclique Child(Base):\n    cook new(fam, value):\n        call up ancestor.new(fam, value=value) yo\nlet c be Child(value=7)\nyap(c.value)\n', '7\n')

    def test_slang_options_aliases_unpacking_and_seed(self):
        self.parity('''yap("a", "b", glue="/", micdrop="!")
yap()
let say be yap
call up say("x", "y", **{"glue": "-", "micdrop": "?"}) yo
yap()
let scores be [3, 1, 2]
yap(call up ranked(scores, uno_reverse=nocap) yo)
yap(scores)
let sortit be ranked
yap(call up sortit(scores, **{"uno_reverse": nocap}) yo)
pull up luck as rng
call up rng.manifest(42) yo
let first be [rng.random(), rng.randint(1, 100), rng.choice([1, 2, 3])]
call up rng.manifest(42) yo
yap(first == [rng.random(), rng.randint(1, 100), rng.choice([1, 2, 3])])
outta luck pull up manifest as reset
call up reset(42) yo
yap(first == [rng.random(), rng.randint(1, 100), rng.choice([1, 2, 3])])
''', 'a/b!\nx-y?\n[3, 2, 1]\n[3, 1, 2]\n[3, 2, 1]\nTrue\nTrue\n')

    def test_export_helpers_allow_builtin_shadowing(self):
        self.parity('let str be 1\nlet bool be 2\nlet int be 3\nlet isinstance be 4\nlet getattr be 5\nyap("ok")\nyap(ranked([2, 1]))\npull up luck\nluck.manifest(0)', 'ok\n[1, 2]\n')

    def test_invalid_keywords_and_types(self):
        for code, message in [
            ('yap("a", end="!")', 'unexpected argument'),
            ('yap("a", glue=1)', 'expects text'),
            ('ranked([1], uno_reverse=1)', 'expects nocap or cap'),
            ('num("1", surprise=1)', 'unexpected argument'),
            ('call up yap("a", **{"glue": "-"}, glue="/") yo', 'multiple values'),
            ('pull up luck\nluck.manifest(1.5)', 'integer seed'),
            ('clique Empty:\n    deadass\nEmpty(x=1)', 'takes no arguments'),
        ]:
            with self.subTest(code=code):
                result = self.run_code(code)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn(message, result.stderr)

    def test_comparison_chain_diagnostic(self):
        for code in ['yap(3 < 2 < 1)', 'yap(1 == 1 == 1)', 'yap(1 up in [1] == nocap)']:
            result = self.run_code(code)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("split comparisons with 'both'", result.stderr)
        self.parity('yap((3 < 2) < 1)\nyap(3 < 2 both 2 < 1)', 'True\nFalse\n')


if __name__ == '__main__':
    unittest.main()

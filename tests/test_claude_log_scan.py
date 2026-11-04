"""bin/claude-log-scan のテスト。

secret らしき文字列の検出と、ログを壊さないマスク処理を検証する。
特に「jsonl の JSON としての妥当性を保つ」「冪等である」「プレースホルダを
誤検出しない」の3点が本質的な要件なので、そこを重点的に見る。
"""

import importlib.machinery
import importlib.util
import json
import os
import stat
import sys
import time
import unittest
from pathlib import Path
from tempfile import TemporaryDirectory

SCRIPT = Path(__file__).resolve().parent.parent / "bin" / "claude-log-scan"


def _load():
    # 拡張子なしの実行ファイルなので loader を明示する
    loader = importlib.machinery.SourceFileLoader("claude_log_scan", str(SCRIPT))
    spec = importlib.util.spec_from_loader("claude_log_scan", loader)
    mod = importlib.util.module_from_spec(spec)
    sys.modules["claude_log_scan"] = mod
    spec.loader.exec_module(mod)
    return mod


cls = _load()

# テスト用のダミー値（実在しないことが保証されている公式サンプル/明らかな偽物）
AWS_KEY = "AKIAIOSFODNN7EXAMPLE"
GH_TOKEN = "ghp_" + "a1B2c3D4e5F6g7H8i9J0k1L2m3N4o5P6q7R8"
ANTHROPIC = "sk-ant-api03-" + "x" * 40
OPENAI = "sk-" + "T3BlbkFJ" + "q" * 32
SLACK = "xoxb-123456789012-123456789012-" + "Zz" * 12
GOOGLE = "AIza" + "Sy" + "C" * 33
STRIPE = "sk_live_" + "4eC39HqLyjWDarjtT1zdp7dc"
DB_PASSWORD = "K7mQ2xZ9pL4vR8nT"
JWT = "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.dBjftJeZ4CVPmB92K27uhbUJU1p1r_wW1gFWFOEjXk"


class TestFindSecrets(unittest.TestCase):
    """構造を持つトークンは高確度で拾えること。"""

    def _rules(self, text):
        return sorted(f.rule for f in cls.scan(text))

    def test_aws_access_key_id(self):
        self.assertEqual(self._rules(f"key is {AWS_KEY} ok"), ["aws-access-key-id"])

    def test_github_token(self):
        self.assertEqual(self._rules(f"token={GH_TOKEN}"), ["github-token"])

    def test_anthropic_key_wins_over_openai(self):
        # sk-ant- は sk- にも一致しうる。より具体的な方だけが1件報告されること。
        self.assertEqual(self._rules(ANTHROPIC), ["anthropic-api-key"])

    def test_openai_key(self):
        self.assertEqual(self._rules(OPENAI), ["openai-api-key"])

    def test_various_vendor_tokens(self):
        for value, expected in [
            (SLACK, "slack-token"),
            (GOOGLE, "google-api-key"),
            (STRIPE, "stripe-key"),
            (JWT, "jwt"),
            ("npm_" + "b" * 36, "npm-token"),
            ("lin_api_" + "c" * 40, "linear-api-key"),
            ("https://hooks.slack.com/services/T00000000/B00000000/" + "d" * 24,
             "slack-webhook"),
        ]:
            with self.subTest(expected):
                self.assertEqual(self._rules(value), [expected])

    def test_private_key_block_is_one_finding(self):
        pem = (
            "-----BEGIN RSA PRIVATE KEY-----\n"
            + "MIIEowIBAAKCAQEA" + "e" * 60 + "\n"
            + "-----END RSA PRIVATE KEY-----"
        )
        found = cls.scan(pem)
        self.assertEqual([f.rule for f in found], ["private-key"])
        # ブロック全体が1つの finding に収まる（断片化しない）
        self.assertEqual(found[0].text, pem)

    def test_private_key_with_escaped_newlines(self):
        # jsonl の中では改行が \n にエスケープされている
        pem = (
            "-----BEGIN OPENSSH PRIVATE KEY-----\\n"
            + "b3BlbnNzaC1rZXk" + "f" * 60 + "\\n"
            + "-----END OPENSSH PRIVATE KEY-----"
        )
        self.assertEqual(self._rules(pem), ["private-key"])

    def test_token_prefixes_need_a_word_boundary(self):
        """ta-sk- のように単語の内側に現れた接頭辞を拾わないこと。

        実ログで openai-api-key が36件出たが、全て `task-...` や `ask-...` の
        中の `sk-` だった。接頭辞マッチは必ず左境界を要求する。
        """
        for text in [
            "task-management-system-for-the-whole-team-abc",
            "ask-the-user-about-the-configuration-value-x",
            "refactor-task-splitting-into-smaller-branches",
        ]:
            with self.subTest(text):
                self.assertEqual(cls.scan(text), [], text)

    def test_ignores_matches_inside_base64_blobs(self):
        """貼り付けた画像の base64 に偶然含まれる並びを拾わないこと。

        トランスクリプトにはスクリーンショットの base64 がそのまま入る。
        実ログでは google-api-key 14件が全てこれだった（AIza + 35文字が
        base64 の途中で成立する）。左境界は英数字全体で切る。
        """
        for text in [
            "iVBORw0KGgoAIzaSyC" + "D" * 33 + "qrstuvw",
            "data:image/png;base64,abcAKIAABCDEFGHIJKLMNOPqrs",
        ]:
            with self.subTest(text):
                self.assertEqual(cls.scan(text), [], text)

    def test_clean_text_has_no_findings(self):
        text = (
            "git commit -m 'fix: PATH order'\n"
            "const handler = async (req, res) => res.json({ ok: true })\n"
            "AKIA is a prefix but AKIASHORT is not a key\n"
        )
        self.assertEqual(cls.scan(text), [])

    def test_offsets_point_at_the_secret(self):
        text = f"prefix {AWS_KEY} suffix"
        f = cls.scan(text)[0]
        self.assertEqual(text[f.start:f.end], AWS_KEY)


class TestGenericAssignment(unittest.TestCase):
    """password= のような代入は拾うが、確度は low に落とすこと。"""

    def test_detects_assignment(self):
        found = cls.scan(f"export DB_PASSWORD={DB_PASSWORD}")
        self.assertEqual([f.rule for f in found], ["generic-assignment"])
        self.assertEqual(found[0].severity, "low")
        # キー名ではなく値だけが対象
        self.assertEqual(found[0].text, DB_PASSWORD)

    def test_structured_rules_are_high_severity(self):
        self.assertEqual(cls.scan(AWS_KEY)[0].severity, "high")

    def test_ignores_placeholders(self):
        for value in [
            "api_key=$API_KEY",
            "api_key=${API_KEY}",
            'apiKey: process.env.API_KEY',
            'api_key: os.environ["API_KEY"]',
            "password=your-password-here",
            "password=changeme",
            "token=xxxxxxxxxxxx",
            "token=************",
            "secret=<your-secret>",
            "password=null",
            "api_key: None",
            "secret_key = ''",
            "token=TODO",
            "password=aaaaaaaaaaaa",
        ]:
            with self.subTest(value):
                self.assertEqual(cls.scan(value), [], value)

    def test_assigned_vendor_token_is_upgraded_to_high(self):
        """TOKEN=ghp_... は代入だが、値が構造を持つので high に昇格すること。

        交替の最左マッチでは左辺の `token` に先に当たるため、素直に書くと
        低確度扱いになり --high-only で取りこぼす。ログ上の secret は
        ほとんどこの形で現れるので、ここが抜けると意味がない。
        """
        for text, expected in [
            (f"token={GH_TOKEN}", "github-token"),
            (f"export AWS_ACCESS_KEY_ID={AWS_KEY}", "aws-access-key-id"),
            (f'{{"api_key":"{ANTHROPIC}"}}', "anthropic-api-key"),
        ]:
            with self.subTest(expected):
                found = cls.scan(text)
                self.assertEqual([f.rule for f in found], [expected])
                self.assertEqual(found[0].severity, "high")

    def test_upgraded_token_survives_high_only(self):
        masked, found = cls.mask_text(f"GITHUB_TOKEN={GH_TOKEN}", high_only=True)
        self.assertEqual([f.rule for f in found], ["github-token"])
        self.assertNotIn(GH_TOKEN, masked)
        self.assertEqual(masked, "GITHUB_TOKEN=[MASKED:github-token]")

    def test_ignores_code_identifiers(self):
        """実ログで誤検出の大半を占めたコードを拾わないこと。

        ~/.claude を実際に走査して出た約980件の generic 検出は、ほぼ全てが
        以下の形だった。secret っぽいキー名への代入という条件だけでは
        コードと区別できないので、値が資格情報の形をしているかまで見る。
        """
        for text in [
            # cdk.Duration.days(30) のようなメソッド呼び出し（実データ最多）
            "refreshTokenValidity: cdk.Duration.days(30)",
            "accessTokenValidity: Duration.minutes(60)",
            # 環境変数・設定値の参照
            "apiKey: process.env.ANTHROPIC_API_KEY",
            "clientSecret: this.config.clientSecret",
            "secret_key = settings.SECRET_KEY_FALLBACK",
            # ただの識別子（camelCase / kebab / dotted）
            "apiKey: someCamelCaseVariable",
            "password-email-ja: password-reset-template",
            "credentialOptions: defaultCredentialProvider",
            # 日本語の文章
            "token: このサービス名は予約されています",
            # 既に伏せられている値
            "api_key = ****************************",
        ]:
            with self.subTest(text):
                self.assertEqual(cls.scan(text), [], text)

    def test_ignores_dotted_code_references(self):
        """env.vars.SECRET_KEY のような参照を拾わないこと。

        実ログに残った generic 検出38件のうち34件がこの形だった。
        ドットで区切られた各部分が識別子なら、値ではなく参照である。
        """
        for text in [
            "secret: env.vars.STRIPE_SECRET_KEY",
            "apiKey: firebase.config.API_KEY",
            "token: ctx.request.headers.authorization",
            "secret = aws.secretsmanager.DatabaseSecret",
        ]:
            with self.subTest(text):
                self.assertEqual(cls.scan(text), [], text)

    def test_detects_uuid_shaped_token(self):
        """UUID 形のトークンは残す。セッショントークンの実体でありうる。"""
        found = cls.scan("authToken=550e8400-e29b-41d4-a716-446655440000")
        self.assertEqual([f.rule for f in found], ["generic-assignment"])

    def test_detects_credential_shaped_values(self):
        for value in [
            "K7mQ2xZ9pL4vR8nT",                      # 英数混在のランダム列
            "aG9sYS1tdW5kby1zZWNyZXQtdmFsdWU=",      # base64
            "9f8e7d6c5b4a39281706f5e4d3c2b1a0",       # hex
        ]:
            with self.subTest(value):
                found = cls.scan(f"SECRET_KEY={value}")
                self.assertEqual([f.text for f in found], [value])

    def test_ignores_short_values(self):
        self.assertEqual(cls.scan("password=abc"), [])

    def test_value_stops_at_json_string_boundary(self):
        # 値の文字クラスが " を含むと JSON の構造を食い潰す
        line = '{"text":"password=' + DB_PASSWORD + '","role":"user"}'
        f = cls.scan(line)[0]
        self.assertEqual(f.text, DB_PASSWORD)


class TestMaskText(unittest.TestCase):
    def test_replaces_only_the_secret(self):
        masked, found = cls.mask_text(f"key is {AWS_KEY} ok")
        self.assertEqual(masked, "key is [MASKED:aws-access-key-id] ok")
        self.assertEqual(len(found), 1)

    def test_is_idempotent(self):
        once, _ = cls.mask_text(f"export AWS_ACCESS_KEY_ID={AWS_KEY}")
        twice, found = cls.mask_text(once)
        self.assertEqual(once, twice)
        self.assertEqual(found, [])

    def test_masks_multiple_secrets_in_one_text(self):
        masked, found = cls.mask_text(f"a={AWS_KEY} b={GH_TOKEN}")
        self.assertEqual(len(found), 2)
        self.assertNotIn(AWS_KEY, masked)
        self.assertNotIn(GH_TOKEN, masked)

    def test_high_only_skips_generic(self):
        text = f"password={DB_PASSWORD} key={AWS_KEY}"
        masked, found = cls.mask_text(text, high_only=True)
        self.assertEqual([f.rule for f in found], ["aws-access-key-id"])
        self.assertIn(DB_PASSWORD, masked)

    def test_keeps_jsonl_line_valid(self):
        original = json.dumps(
            {"role": "user", "content": f"export GITHUB_TOKEN={GH_TOKEN}", "n": 1}
        )
        masked, _ = cls.mask_text(original)
        obj = json.loads(masked)  # ここで壊れていれば resume が死ぬ
        self.assertEqual(obj["role"], "user")
        self.assertEqual(obj["n"], 1)
        self.assertNotIn(GH_TOKEN, masked)

    def test_keeps_jsonl_valid_with_embedded_private_key(self):
        pem = (
            "-----BEGIN RSA PRIVATE KEY-----\n"
            + "MIIEowIBAAKCAQEA" + "g" * 60 + "\n"
            + "-----END RSA PRIVATE KEY-----"
        )
        original = json.dumps({"content": pem, "after": "kept"})
        masked, found = cls.mask_text(original)
        self.assertEqual(json.loads(masked)["after"], "kept")
        self.assertEqual(len(found), 1)

    def test_redacted_preview_never_leaks_the_secret(self):
        f = cls.scan(AWS_KEY)[0]
        preview = f.preview()
        self.assertNotIn(AWS_KEY, preview)
        self.assertTrue(preview.startswith("AKIA"))


class TestFileHandling(unittest.TestCase):
    def setUp(self):
        self._tmp = TemporaryDirectory()
        self.dir = Path(self._tmp.name)
        self.addCleanup(self._tmp.cleanup)

    def _write(self, name, text, age_minutes=60, mode=0o600):
        p = self.dir / name
        p.write_text(text)
        p.chmod(mode)
        old = time.time() - age_minutes * 60
        os.utime(p, (old, old))
        return p

    def test_dry_run_does_not_touch_the_file(self):
        p = self._write("a.jsonl", json.dumps({"c": AWS_KEY}) + "\n")
        before = p.read_text()
        result = cls.process_file(p, apply=False)
        self.assertEqual(len(result.findings), 1)
        self.assertEqual(p.read_text(), before)

    def test_apply_rewrites_and_keeps_jsonl_parseable(self):
        p = self._write("a.jsonl", json.dumps({"c": f"k={AWS_KEY}", "keep": 2}) + "\n")
        result = cls.process_file(p, apply=True)
        self.assertTrue(result.changed)
        obj = json.loads(p.read_text())
        self.assertEqual(obj["keep"], 2)
        self.assertNotIn(AWS_KEY, p.read_text())

    def test_apply_preserves_permissions(self):
        p = self._write("a.jsonl", json.dumps({"c": AWS_KEY}) + "\n", mode=0o600)
        cls.process_file(p, apply=True)
        self.assertEqual(stat.S_IMODE(p.stat().st_mode), 0o600)

    def test_skips_recently_modified_file(self):
        p = self._write("a.jsonl", json.dumps({"c": AWS_KEY}) + "\n", age_minutes=0)
        result = cls.process_file(p, apply=True, min_age_minutes=5)
        self.assertEqual(result.skipped, "too-recent")
        self.assertIn(AWS_KEY, p.read_text())

    def test_skips_binary_file(self):
        p = self.dir / "model.bin"
        p.write_bytes(b"\x00\x01\x02" + AWS_KEY.encode() + b"\x00")
        result = cls.process_file(p, apply=True)
        self.assertEqual(result.skipped, "binary")
        self.assertEqual(result.findings, [])

    def test_skips_oversized_file(self):
        p = self._write("big.jsonl", "x" * 5000)
        result = cls.process_file(p, apply=True, max_bytes=1000)
        self.assertEqual(result.skipped, "too-large")

    def test_clean_file_is_not_rewritten(self):
        p = self._write("a.jsonl", json.dumps({"c": "nothing here"}) + "\n")
        mtime = p.stat().st_mtime
        result = cls.process_file(p, apply=True)
        self.assertFalse(result.changed)
        self.assertEqual(p.stat().st_mtime, mtime)

    def test_aborts_when_masking_would_break_json(self):
        # マスク後に壊れる細工をしても、元ファイルは守られること
        p = self._write("a.jsonl", json.dumps({"c": AWS_KEY}) + "\n")
        before = p.read_text()
        result = cls.process_file(
            p, apply=True, _mask=lambda text, **kw: ("{broken", cls.scan(text))
        )
        self.assertEqual(result.skipped, "would-break-json")
        self.assertEqual(p.read_text(), before)

    def test_findings_report_line_numbers(self):
        p = self._write(
            "a.jsonl",
            json.dumps({"c": "clean"}) + "\n" + json.dumps({"c": AWS_KEY}) + "\n",
        )
        result = cls.process_file(p, apply=False)
        self.assertEqual([f.line for f in result.findings], [2])


class TestTargetDiscovery(unittest.TestCase):
    def setUp(self):
        self._tmp = TemporaryDirectory()
        self.root = Path(self._tmp.name)
        self.addCleanup(self._tmp.cleanup)

    def test_collects_jsonl_under_projects_recursively(self):
        (self.root / "projects" / "p" / "subagents").mkdir(parents=True)
        (self.root / "projects" / "p" / "a.jsonl").touch()
        (self.root / "projects" / "p" / "subagents" / "b.jsonl").touch()
        (self.root / "projects" / "p" / "memory").mkdir()
        (self.root / "projects" / "p" / "memory" / "note.md").touch()
        (self.root / "history.jsonl").touch()

        found = {p.name for p in cls.iter_targets([self.root])}
        self.assertEqual(found, {"a.jsonl", "b.jsonl", "note.md", "history.jsonl"})

    def test_ignores_missing_roots(self):
        self.assertEqual(list(cls.iter_targets([self.root / "nope"])), [])

    def test_skips_dot_directories(self):
        (self.root / ".git").mkdir()
        (self.root / ".git" / "config").touch()
        self.assertEqual(list(cls.iter_targets([self.root])), [])


if __name__ == "__main__":
    unittest.main(verbosity=2)

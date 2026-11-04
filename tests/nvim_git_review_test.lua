-- nvim/lua/plugins/git.lua のプラグイン spec を検証する。
-- プラグインは実際にインストールせず、spec テーブルの構造だけを見る。
-- 実行: nvim -l tests/nvim_git_review_test.lua
local repo_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h")
local spec_path = repo_root .. "/nvim/lua/plugins/git.lua"

local failures = 0
local function ok(msg) io.write("ok   - " .. msg .. "\n") end
local function fail(msg)
  io.write("FAIL - " .. msg .. "\n")
  failures = failures + 1
end
local function check(cond, msg) if cond then ok(msg) else fail(msg) end end

if vim.fn.filereadable(spec_path) == 0 then
  fail("nvim/lua/plugins/git.lua が存在する")
  os.exit(1)
end
ok("nvim/lua/plugins/git.lua が存在する")

local loaded, spec = pcall(dofile, spec_path)
if not loaded then
  fail("git.lua が Lua として読める（" .. tostring(spec) .. "）")
  os.exit(1)
end
ok("git.lua が Lua として読める")
check(type(spec) == "table", "git.lua は spec テーブルを返す")

-- spec を走査して、プラグイン名と keys の lhs/rhs を集める
local repos, lhs_list, rhs_list = {}, {}, {}
for _, plugin in ipairs(spec) do
  local name = type(plugin) == "string" and plugin or plugin[1]
  if name then repos[name] = plugin end
  if type(plugin) == "table" and type(plugin.keys) == "table" then
    for _, key in ipairs(plugin.keys) do
      if type(key) == "table" then
        table.insert(lhs_list, key[1])
        if type(key[2]) == "string" then table.insert(rhs_list, key[2]) end
      end
    end
  end
end

local function has_rhs(pattern)
  for _, rhs in ipairs(rhs_list) do
    if rhs:find(pattern, 1, true) then return true end
  end
  return false
end

-- 必要なプラグインが宣言されているか
check(repos["lewis6991/gitsigns.nvim"] ~= nil, "gitsigns.nvim が宣言されている")
check(repos["sindrets/diffview.nvim"] ~= nil, "diffview.nvim が宣言されている")
check(repos["kdheepak/lazygit.nvim"] ~= nil, "lazygit.nvim が宣言されている")

-- レビューの入口となるコマンドが割り当てられているか
check(has_rhs("LazyGit"), "lazygit を開くキーがある")
check(has_rhs("DiffviewOpen"), "diffview を開くキーがある")
check(has_rhs("main...HEAD"), "main との差分をレビューするキーがある")

-- 既存の <leader>g（Telescope live_grep）を遅延させないこと。
-- <leader>g が完全な対応付けなので、<leader>gX を足すと timeoutlen 待ちが発生する。
for _, lhs in ipairs(lhs_list) do
  if lhs:match("^<leader>g.") then
    fail("既存の <leader>g (live_grep) と衝突しない（衝突: " .. lhs .. "）")
  end
end
check(
  not vim.iter(lhs_list):any(function(lhs) return lhs:match("^<leader>g.") ~= nil end),
  "既存の <leader>g (live_grep) と衝突しない"
)

if failures == 0 then
  io.write("All tests passed.\n")
else
  io.write(failures .. " test(s) failed.\n")
  os.exit(1)
end

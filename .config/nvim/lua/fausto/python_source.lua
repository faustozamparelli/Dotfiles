local M = {}

local resolver = [=[
import ast
import importlib
import inspect
import json
import os
import sys


def imported_names(source_path):
    names = {}
    if not source_path or not os.path.isfile(source_path):
        return names

    try:
        with open(source_path, "r", encoding="utf-8") as source:
            tree = ast.parse(source.read(), filename=source_path)
    except (OSError, SyntaxError, UnicodeError):
        return names

    for node in ast.walk(tree):
        if isinstance(node, ast.Import):
            for item in node.names:
                local_name = item.asname or item.name.split(".")[0]
                names[local_name] = item.name if item.asname else item.name.split(".")[0]
        elif isinstance(node, ast.ImportFrom) and node.level == 0 and node.module:
            for item in node.names:
                if item.name != "*":
                    names[item.asname or item.name] = f"{node.module}.{item.name}"
    return names


def resolve(expression, source_path):
    parts = expression.split(".")
    aliases = imported_names(source_path)
    if parts[0] in aliases:
        parts = aliases[parts[0]].split(".") + parts[1:]

    for boundary in range(len(parts), 0, -1):
        module_name = ".".join(parts[:boundary])
        try:
            value = importlib.import_module(module_name)
        except Exception:
            continue

        try:
            for attribute in parts[boundary:]:
                value = getattr(value, attribute)
            return inspect.unwrap(value)
        except (AttributeError, ValueError):
            continue

    raise LookupError(f"could not import or resolve {expression!r}")


try:
    target = resolve(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else "")
    path = inspect.getsourcefile(target) or inspect.getfile(target)
    if not path or path.endswith(".pyi"):
        raise LookupError("only a stub or compiled implementation is available")
    try:
        line = inspect.getsourcelines(target)[1]
    except (OSError, TypeError):
        line = 1
    print(json.dumps({"path": os.path.abspath(path), "line": line}))
except Exception as error:
    print(str(error), file=sys.stderr)
    raise SystemExit(1)
]=]

local function expression_under_cursor()
    local line = vim.api.nvim_get_current_line()
    local cursor = vim.api.nvim_win_get_cursor(0)[2] + 1
    local first = cursor
    local last = cursor

    while first > 1 and line:sub(first - 1, first - 1):match('[%w_.]') do
        first = first - 1
    end
    while last <= #line and line:sub(last, last):match('[%w_.]') do
        last = last + 1
    end

    return line:sub(first, last - 1):gsub('^%.+', ''):gsub('%.$', '')
end

local function python_executable(source_path)
    local start = source_path ~= '' and vim.fs.dirname(source_path) or vim.fn.getcwd()
    local virtual_environment = vim.fs.find('.venv', { path = start, upward = true, type = 'directory' })[1]
    if virtual_environment then
        local candidate = virtual_environment .. '/bin/python'
        if vim.fn.executable(candidate) == 1 then
            return candidate
        end
    end

    if vim.env.VIRTUAL_ENV then
        local candidate = vim.env.VIRTUAL_ENV .. '/bin/python'
        if vim.fn.executable(candidate) == 1 then
            return candidate
        end
    end

    local python = vim.fn.exepath('python3')
    return python ~= '' and python or vim.fn.exepath('python')
end

function M.open()
    if vim.bo.filetype ~= 'python' then
        vim.notify('Python source lookup is only available in Python buffers', vim.log.levels.WARN)
        return
    end

    local expression = expression_under_cursor()
    if expression == '' then
        vim.notify('Place the cursor on a Python name first', vim.log.levels.WARN)
        return
    end

    local source_path = vim.api.nvim_buf_get_name(0)
    local python = python_executable(source_path)
    if python == '' then
        vim.notify('Could not find a Python interpreter', vim.log.levels.ERROR)
        return
    end

    vim.system({ python, '-c', resolver, expression, source_path }, {
        cwd = source_path ~= '' and vim.fs.dirname(source_path) or vim.fn.getcwd(),
        text = true,
    }, function(result)
        vim.schedule(function()
            if result.code ~= 0 then
                local reason = vim.trim(result.stderr or '')
                vim.notify(
                    string.format('Could not find Python source for %s%s', expression, reason ~= '' and ': ' .. reason or ''),
                    vim.log.levels.WARN
                )
                return
            end

            local ok, location = pcall(vim.json.decode, result.stdout)
            if not ok or type(location) ~= 'table' or type(location.path) ~= 'string' then
                vim.notify('Python source lookup returned an invalid location', vim.log.levels.ERROR)
                return
            end

            vim.cmd.edit(vim.fn.fnameescape(location.path))
            vim.api.nvim_win_set_cursor(0, { math.max(1, location.line or 1), 0 })
            vim.cmd.normal({ 'zz', bang = true })
        end)
    end)
end

return M

#!/usr/bin/env python3
import os
import re
import shlex
import shutil
import subprocess
import sys
from pathlib import Path


VAR_REF_RE = re.compile(r"\$\(([^()]+)\)|\$\{([^{}]+)\}")


def run(cmd):
    return subprocess.check_output(cmd, text=True).strip()


def die(msg):
    print(msg, file=sys.stderr)
    return 1


def find_r():
    for exe in ("R", "R.exe"):
        path = shutil.which(exe)
        if path:
            return path
    return None


def r_cmd_config(r_bin, var):
    return run([r_bin, "CMD", "config", var])


def r_eval(r_bin, expr):
    rscript = shutil.which("Rscript")
    if rscript:
        out = run([rscript, "--vanilla", "-e", f"cat({expr})"])
    else:
        out = run([r_bin, "--vanilla", "--slave", "-e", f"cat({expr})"])
    lines = [line.strip() for line in out.splitlines() if line.strip()]
    return lines[-1] if lines else ""


def rcpp_include_dir(r_bin):
    try:
        path = r_eval(r_bin, "system.file('include', package = 'Rcpp')")
        return path if path else None
    except Exception:
        return None


def read_makevars(path):
    if not path or not path.exists():
        return {}
    lines = path.read_text().splitlines()
    joined = []
    buf = ""
    for line in lines:
        if "#" in line:
            line = line.split("#", 1)[0]
        line = line.rstrip()
        if not line:
            continue
        if line.endswith("\\"):
            buf += line[:-1] + " "
            continue
        buf += line
        joined.append(buf.strip())
        buf = ""
    if buf:
        joined.append(buf.strip())

    vars_map = {}
    for line in joined:
        if "+=" in line:
            name, val = line.split("+=", 1)
            name = name.strip()
            val = val.strip()
            if not name:
                continue
            prev = vars_map.get(name, "")
            vars_map[name] = (prev + " " + val).strip() if prev else val
        elif "=" in line:
            name, val = line.split("=", 1)
            name = name.strip()
            val = val.strip()
            if name:
                vars_map[name] = val
    return vars_map


def dedupe(seq):
    out, seen = [], set()
    paired_flags = {"-F", "-I", "-iquote", "-isystem"}
    i = 0
    while i < len(seq):
        item = seq[i]
        if item in paired_flags and i + 1 < len(seq):
            pair = (item, seq[i + 1])
            if pair not in seen:
                out.extend(pair)
                seen.add(pair)
            i += 2
            continue
        if item not in seen:
            out.append(item)
            seen.add(item)
        i += 1
    return out


def find_makevars(src_dir):
    for name in ("Makevars", "Makevars.in"):
        path = src_dir / name
        if path.exists():
            return path
    return None


def make_r_config_getter(r_bin):
    cache = {}

    def getter(var):
        if var not in cache:
            try:
                cache[var] = r_cmd_config(r_bin, var)
            except Exception:
                cache[var] = ""
        return cache[var]

    return getter


def expand_makevars_vars(value, vars_map, context, r_config):
    cache = {}

    def resolve(name, stack):
        if name in cache:
            return cache[name]
        if name in stack:
            return ""

        if name in context:
            raw = context[name]
        elif name in vars_map:
            raw = vars_map[name]
        else:
            raw = os.environ.get(name) or r_config(name)

        if raw is None:
            raw = ""

        next_stack = stack | {name}
        expanded = VAR_REF_RE.sub(
            lambda match: resolve(match.group(1) or match.group(2), next_stack),
            raw,
        )
        cache[name] = expanded
        return expanded

    return VAR_REF_RE.sub(
        lambda match: resolve(match.group(1) or match.group(2), set()),
        value,
    )


def normalize_path_flags(flags, base_dir):
    out = []
    i = 0
    while i < len(flags):
        token = flags[i]
        if token in {"-F", "-I", "-isystem", "-iquote"}:
            if i + 1 < len(flags):
                path = flags[i + 1]
                if not os.path.isabs(path):
                    path = str((base_dir / path).resolve())
                out.extend([token, path])
                i += 2
                continue
        if token.startswith("-F") and len(token) > 2:
            path = token[2:]
            if not os.path.isabs(path):
                path = str((base_dir / path).resolve())
            out.append("-F" + path)
            i += 1
            continue
        if token.startswith("-I") and len(token) > 2:
            path = token[2:]
            if not os.path.isabs(path):
                path = str((base_dir / path).resolve())
            out.append("-I" + path)
            i += 1
            continue
        if token.startswith("-isystem") and len(token) > len("-isystem"):
            path = token[len("-isystem") :]
            if path.startswith("="):
                path = path[1:]
                if not os.path.isabs(path):
                    path = str((base_dir / path).resolve())
                out.append("-isystem=" + path)
            else:
                if not os.path.isabs(path):
                    path = str((base_dir / path).resolve())
                out.append("-isystem" + path)
            i += 1
            continue
        out.append(token)
        i += 1
    return out


def makevars_context(vars_map, r_home):
    context = {}
    if r_home:
        context["R_HOME"] = r_home
        context["R_INCLUDE_DIR"] = str(Path(r_home) / "include")
    return context


def makevars_flags(src_dir, vars_map, context, r_config, lang):
    keys = ["PKG_CPPFLAGS"]
    if lang == "c":
        keys.append("PKG_CFLAGS")
    else:
        keys.append("PKG_CXXFLAGS")

    flags = []
    for key in keys:
        val = vars_map.get(key)
        if not val:
            continue
        expanded = expand_makevars_vars(val, vars_map, context, r_config).strip()
        if expanded:
            flags += shlex.split(expanded)
    return normalize_path_flags(flags, src_dir)


def cxx_std_setting(vars_map, context, r_config):
    value = vars_map.get("CXX_STD", "").strip()
    if not value:
        return ""
    return expand_makevars_vars(value, vars_map, context, r_config).strip()


def compiler_command(r_config, lang, cxx_std):
    if lang == "c":
        command = r_config("CC")
    else:
        command = r_config(cxx_std or "CXX") or r_config("CXX")
    return shlex.split(command) if command else []


def compiler_flag_vars(lang, cxx_std):
    if lang == "c":
        return ("CFLAGS", "")
    if cxx_std:
        return (f"{cxx_std}FLAGS", f"{cxx_std}STD")
    return ("CXXFLAGS", "")


def parse_include_search_paths(output):
    paths = []
    in_search_list = False
    for line in output.splitlines():
        stripped = line.strip()
        if stripped in {
            '#include "..." search starts here:',
            "#include <...> search starts here:",
        }:
            in_search_list = True
            continue
        if in_search_list and stripped == "End of search list.":
            break
        if not in_search_list or not stripped:
            continue
        if stripped.endswith("(framework directory)"):
            path = stripped[: -len("(framework directory)")].strip()
            if path and os.path.isdir(path):
                paths.extend(["-F", path])
            continue
        if os.path.isdir(stripped):
            paths.extend(["-isystem", stripped])
    return paths


def compiler_include_flags(compiler, lang, std_flags):
    if not compiler:
        return []
    cmd = compiler + ["-E", "-x", lang] + std_flags + ["-v", "-"]
    try:
        proc = subprocess.run(
            cmd,
            input="",
            text=True,
            capture_output=True,
            check=False,
        )
    except OSError:
        return []
    output = "\n".join(part for part in (proc.stderr, proc.stdout) if part)
    return parse_include_search_paths(output)


def build_flags(r_bin, lang, root):
    flags = []
    r_home = None
    try:
        r_home = run([r_bin, "RHOME"])
    except Exception:
        pass

    pkg = root / "RcppTskit"
    src_dir = pkg / "src"
    makevars = find_makevars(src_dir)
    vars_map = read_makevars(makevars) if makevars else {}
    r_config = make_r_config_getter(r_bin)
    context = makevars_context(vars_map, r_home)
    cxx_std = cxx_std_setting(vars_map, context, r_config) if lang != "c" else ""

    flags += makevars_flags(src_dir, vars_map, context, r_config, lang)

    cppflags = r_config("CPPFLAGS")
    if cppflags:
        flags += shlex.split(cppflags)

    flags_var, std_var = compiler_flag_vars(lang, cxx_std)
    compiler_flags = r_config(flags_var)
    if compiler_flags:
        flags += shlex.split(compiler_flags)
    if std_var:
        std_flags = shlex.split(r_config(std_var))
        flags += std_flags
    else:
        std_flags = []

    rcpp_inc = rcpp_include_dir(r_bin)
    if rcpp_inc:
        flags.append(f"-I{rcpp_inc}")

    include_paths = [
        pkg / "inst" / "include",
        pkg / "inst" / "include" / "tskit",
        pkg / "inst" / "include" / "tskit" / "tskit",
    ]
    for p in include_paths:
        flags.append(f"-I{p}")

    if r_home:
        flags.append(f"-I{Path(r_home) / 'include'}")

    flags += compiler_include_flags(
        compiler_command(r_config, lang, cxx_std),
        lang,
        std_flags,
    )

    flags = normalize_path_flags(flags, src_dir)

    if "-DNDEBUG" not in flags:
        flags.append("-DNDEBUG")

    return dedupe(flags)


def guess_language(path):
    ext = path.suffix.lower()
    if ext == ".c":
        return "c"
    if ext in {".cc", ".cxx", ".cpp"}:
        return "c++"
    if ext in {".hpp", ".hxx", ".hh"}:
        return "c++"
    return "c"


def split_args(args):
    if "--" in args:
        idx = args.index("--")
        return args[:idx], args[idx + 1 :]
    return args, []


def main(argv):
    paths, extra = split_args(argv)
    if not paths:
        return die("No input files provided.")

    r_bin = find_r()
    if not r_bin:
        return die("R not found on PATH; install R or set PATH accordingly.")

    clang_tidy = os.environ.get("CLANG_TIDY") or shutil.which("clang-tidy")
    if not clang_tidy:
        return die("clang-tidy not found on PATH; install LLVM/clang-tidy.")

    root = Path(__file__).resolve().parents[2]
    exit_code = 0

    for p in paths:
        path = Path(p)
        lang = guess_language(path)
        flags = build_flags(r_bin, lang, root)
        if path.suffix.lower() in {".h", ".hh", ".hpp", ".hxx"}:
            flags = ["-x", "c" if lang == "c" else "c++"] + flags
        cmd = [clang_tidy, str(path)] + extra + ["--"] + flags
        rc = subprocess.call(cmd)
        if rc != 0:
            exit_code = rc

    return exit_code


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

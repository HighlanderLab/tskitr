#!/usr/bin/env python3
import os
import shlex
import shutil
import subprocess
import sys
from pathlib import Path


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
    for item in seq:
        if item not in seen:
            out.append(item)
            seen.add(item)
    return out


def normalize_path_flags(flags, base_dir):
    out = []
    i = 0
    while i < len(flags):
        token = flags[i]
        if token in {"-I", "-isystem", "-iquote"}:
            if i + 1 < len(flags):
                path = flags[i + 1]
                if not os.path.isabs(path):
                    path = str((base_dir / path).resolve())
                out.extend([token, path])
                i += 2
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


def makevars_flags(src_dir, r_home, lang):
    makevars = src_dir / "Makevars"
    if not makevars.exists():
        makevars = src_dir / "Makevars.in"
    vars_map = read_makevars(makevars)
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
        if r_home:
            val = val.replace("$(R_HOME)", r_home).replace("${R_HOME}", r_home)
        flags += shlex.split(val)
    return normalize_path_flags(flags, src_dir)


def build_flags(r_bin, lang, root):
    flags = []
    r_home = None
    try:
        r_home = run([r_bin, "RHOME"])
    except Exception:
        pass

    pkg = root / "RcppTskit"
    src_dir = pkg / "src"

    flags += makevars_flags(src_dir, r_home, lang)

    cppflags = r_cmd_config(r_bin, "CPPFLAGS")
    if cppflags:
        flags += shlex.split(cppflags)

    if lang == "c":
        cflags = r_cmd_config(r_bin, "CFLAGS")
        if cflags:
            flags += shlex.split(cflags)
    else:
        cxxflags = r_cmd_config(r_bin, "CXXFLAGS")
        if cxxflags:
            flags += shlex.split(cxxflags)

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

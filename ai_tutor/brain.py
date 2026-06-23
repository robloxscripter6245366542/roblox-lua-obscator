"""AI brain – natural language understanding and response generation."""

import re
import random
from .knowledge.general_kb  import CONCEPTS, ALIASES
from .knowledge.languages_kb import LANGUAGES, LANG_ALIASES

# ─── Intent definitions ──────────────────────────────────────────────────────

INTENTS = {
    "greet": [
        r"\b(hello|hi|hey|howdy|sup|what'?s up|hola|good (morning|afternoon|evening))\b",
        r"^(hi|hey|hello)\.?$",
    ],
    "help": [
        r"\b(help|commands|what can you do|options|menu|guide)\b",
    ],
    # quiz BEFORE exercise – "quiz me" must not fall through to exercise
    "quiz": [
        r"\bquiz me\b",
        r"\bquiz (me )?(on|about)\b",
        r"\btest my knowledge\b",
        r"\bask me (about|on)?\b",
    ],
    # fetch BEFORE learn_language – "search X" must not trigger language lookup
    "fetch": [
        r"\b(fetch|browse|search the web|look up|web search|search online)\b",
        r"^search\b",                    # "search ..." at start of input
        r"\bsearch for\b",
        r"\b(search|find online|google)\b.+\b(tutorial|docs?|how to|guide|example)\b",
        r"\bfetch https?://",
        r"\b(open|visit|go to) https?://",
    ],
    "learn_concept": [
        r"\b(what is|what are|explain|tell me about|how does|describe|define|definition of)\b",
        r"\b(teach me|show me|help me understand)\b.*\b(what|how|why)\b",
    ],
    "learn_language": [
        r"\b(teach me|learn|show me|tutorial|guide to|intro to|introduce me to)\b.*(python|javascript|js|lua|java|c\+\+|cpp|rust|go|golang|typescript|ts|sql|html|css)",
        r"\b(python|javascript|lua|java|rust|golang|typescript|sql|html|css)\b.*(tutorial|guide|basics|intro|beginner|syntax)",
        r"\bshow me (python|javascript|lua|java|c\+\+|rust|go|typescript|sql|html|css)\b",
        r"^(python|javascript|lua|java|rust|go|golang|typescript|sql|html|css)$",
    ],
    "exercise": [
        r"\b(exercise|challenge|coding problem|give me a (problem|challenge|task))\b",
        r"\b(let me try|i want to practice)\b",
    ],
    "hint": [
        r"\b(hint|help me|stuck|i don'?t know|no idea|clue|tip)\b",
    ],
    "solution": [
        r"\b(solution|answer|show (me the )?answer|give me the solution|reveal|solved?)\b",
    ],
    "analyze_code": [
        r"```[\s\S]+```",                            # fenced code block
        r"\b(analyze|review|check|debug|fix|what'?s wrong with|explain this code)\b",
        r"(def |function |class |for |while |if |import |local )",
    ],
    "compare_languages": [
        r"\b(difference|compare|vs\.?|versus|better|which is better)\b.*(language|python|js|java|lua|rust|go)",
        r"\b(python|js|java|lua|rust|go)\b.*(vs\.?|versus|or|compared to)\b",
    ],
    "best_practices": [
        r"\b(best practice|best way|how should|proper way|correct way|clean code|good code)\b",
        r"\b(tips?|advice|suggest|recommend)\b.*(coding|programming|writing code)\b",
        r"^best practices?$",
    ],
    "career": [
        r"\b(career|job|salary|which language|should i learn|start with|beginner language)\b",
        r"\b(become a (programmer|developer|engineer)|get (a|into) (coding|programming))\b",
    ],
    "project_ideas": [
        r"\b(project ideas?|what (can|should) i build|build something|idea for a project|give me.*(idea|project))\b",
    ],
    "generate": [
        r"\b(generate|create|make|build|write|give me|produce)\b.*(code|script|ui|page|app|website|3d|animation|api|server|database|schema|roblox|three\.?js|css|html)",
        r"\bgenerate\b",
        r"\b(3d scene|landing page|dashboard|portfolio|react app|flask api|express|scraper|sql schema|roblox gui|roblox npc|game loop)\b",
    ],
    "read_file": [
        r"\b(read|open|show|display|view)\b.*\b(file|\.py|\.js|\.lua|\.txt|\.json|\.html|\.css)\b",
        r"\bread file\b",
    ],
    "write_file": [
        r"\b(write|save|create)\b.*\b(file|\.py|\.js|\.lua|\.txt)\b",
        r"\bsave (this|the) (code|script) to\b",
    ],
    "list_files": [
        r"\b(list|ls|dir|show)\b.*(files?|directory|folder|contents?)\b",
    ],
    "profile": [
        r"\b(profile|my info|who am i|remember me|what do you know about me)\b",
        r"\bmy name is\b",
    ],
    "correct": [
        r"\b(that('s| is) wrong|incorrect|not right|you made an error|fix that|that('s| is) not right)\b",
    ],
    "goodbye": [
        r"\b(bye|goodbye|exit|quit|see you|later|cya|gotta go|farewell)\b",
    ],
    "thanks": [
        r"\b(thank|thanks|thx|ty|appreciate|great|awesome|nice|perfect|cool)\b",
    ],
    "topics": [
        r"\b(topics?|subjects?|what can i learn|list (of )?topics|curriculum|syllabus)\b",
    ],
    "progress": [
        r"\b(progress|score|points?|xp|level|how (am i|do i))\b",
    ],
}

# ─── Concept / language keyword extraction ───────────────────────────────────

def _normalise(text: str) -> str:
    return re.sub(r"\s+", " ", text.strip().lower())


def _extract_concept(text: str):
    """Return (concept_key, concept_dict) or (None, None)."""
    t = _normalise(text)
    # direct key
    for key in CONCEPTS:
        if key in t:
            return key, CONCEPTS[key]
    # aliases
    for alias, key in ALIASES.items():
        if alias in t:
            return key, CONCEPTS[key]
    return None, None


def _extract_language(text: str):
    """Return (lang_key, lang_dict) or (None, None)."""
    t = _normalise(text)
    for alias, key in LANG_ALIASES.items():
        if re.search(r'\b' + re.escape(alias) + r'\b', t):
            return key, LANGUAGES[key]
    for key in LANGUAGES:
        if re.search(r'\b' + re.escape(key) + r'\b', t):
            return key, LANGUAGES[key]
    return None, None


# ─── Intent classifier ───────────────────────────────────────────────────────

def classify_intent(text: str) -> str:
    t = _normalise(text)
    for intent, patterns in INTENTS.items():
        for pattern in patterns:
            if re.search(pattern, t, re.IGNORECASE):
                return intent
    return "unknown"


# ─── Response generators ─────────────────────────────────────────────────────

def _box(title: str, body: str, width: int = 70) -> str:
    line = "─" * width
    return f"\n╔{line}╗\n║  {title.upper().ljust(width-1)}║\n╠{line}╣\n{body}\n╚{line}╝"


def _wrap(text: str, prefix: str = "║  ", width: int = 70) -> str:
    import textwrap
    lines = text.split("\n")
    result = []
    for line in lines:
        if len(line) == 0:
            result.append(prefix.rstrip())
        elif len(line) > width - len(prefix):
            wrapped = textwrap.wrap(line, width - len(prefix))
            result.extend(prefix + l for l in wrapped)
        else:
            result.append(prefix + line)
    return "\n".join(result)


GREETINGS = [
    "Hey there! I'm CodeMind AI, your personal coding tutor. Ready to learn?",
    "Hello! Welcome to CodeMind AI. What would you like to learn today?",
    "Hey! Great to meet you. I can teach you any programming concept or language. What's on your mind?",
    "Hi! I'm CodeMind — your AI coding tutor. Let's level up your skills!",
]

THANKS_RESPONSES = [
    "You're welcome! Keep coding!",
    "Happy to help! Any other questions?",
    "Glad I could explain that! Want to try an exercise to practice?",
    "Anytime! Learning is a journey — what's next?",
    "Of course! Type 'exercise' to practice what you just learned.",
]

FAREWELL = [
    "Goodbye! Keep coding and don't give up — every expert was once a beginner.",
    "See you! Remember: the best way to learn programming is to build things.",
    "Bye! Practice a little every day and you'll be amazed at your progress.",
]


def respond_greet() -> str:
    return (
        f"  {random.choice(GREETINGS)}\n\n"
        "  Try one of these to get started:\n"
        "    • 'teach me Python'          → full language tutorial\n"
        "    • 'what is a loop?'          → concept explanation\n"
        "    • 'give me an exercise'      → coding challenge\n"
        "    • 'quiz me on functions'     → test your knowledge\n"
        "    • 'compare Python vs JS'     → language comparison\n"
        "    • 'topics'                   → see everything I can teach\n"
        "    • 'help'                     → full command list"
    )


def respond_help() -> str:
    return (
        "\n  ╔══════════════ CODEMIND AI — COMMANDS ══════════════╗\n"
        "  ║                                                       ║\n"
        "  ║  LEARNING                                             ║\n"
        "  ║    teach me <language>    – full language guide       ║\n"
        "  ║    what is <concept>?     – concept explanation       ║\n"
        "  ║    topics                 – list all topics           ║\n"
        "  ║    compare X vs Y         – compare languages         ║\n"
        "  ║    best practices         – coding tips               ║\n"
        "  ║                                                       ║\n"
        "  ║  PRACTICE                                             ║\n"
        "  ║    exercise               – coding challenge          ║\n"
        "  ║    exercise <level>       – beginner/intermediate/adv ║\n"
        "  ║    quiz me on <topic>     – multiple choice quiz      ║\n"
        "  ║    hint                   – get a hint                ║\n"
        "  ║    solution               – see the solution          ║\n"
        "  ║                                                       ║\n"
        "  ║  OTHER                                                ║\n"
        "  ║    career advice          – where to start            ║\n"
        "  ║    project ideas          – things to build           ║\n"
        "  ║    progress               – see your stats            ║\n"
        "  ║    quit / bye             – exit                      ║\n"
        "  ║                                                       ║\n"
        "  ╚═══════════════════════════════════════════════════════╝"
    )


def respond_concept(concept_key: str, concept: dict) -> str:
    out = [f"\n  📚 {concept['title']}\n", "  " + "─" * 60]
    out.append("")
    for line in concept["explanation"].split("\n"):
        out.append("  " + line)
    out.append("\n  " + "─" * 60)
    out.append("  KEY POINTS:")
    for pt in concept["key_points"]:
        out.append(f"    ✓ {pt}")
    out.append(
        f"\n  Type 'quiz me on {concept_key}' to test yourself,\n"
        f"  or 'exercise' to practice with a challenge."
    )
    return "\n".join(out)


def respond_language(lang_key: str, lang: dict) -> str:
    out = [f"\n  🖥️  {lang['title']} — Complete Guide\n", "  " + "═" * 65]
    out.append("")
    for line in lang["overview"].split("\n"):
        out.append("  " + line)
    out.append("\n  " + "─" * 65)
    out.append("  SYNTAX REFERENCE:")
    for line in lang["syntax_guide"].split("\n"):
        out.append("  " + line)
    if "tips" in lang:
        out.append("\n  " + "─" * 65)
        out.append("  PRO TIPS:")
        for tip in lang["tips"]:
            out.append(f"    💡 {tip}")
    if "popular_libraries" in lang:
        out.append("\n  " + "─" * 65)
        out.append("  POPULAR LIBRARIES / FRAMEWORKS:")
        for lib, desc in lang["popular_libraries"].items():
            out.append(f"    📦 {lib:<18} – {desc}")
    out.append(
        f"\n  Type 'exercise' to practice {lang['title']} challenges,\n"
        f"  or 'what is <concept>?' to dive deeper."
    )
    return "\n".join(out)


def respond_topics() -> str:
    out = ["\n  📖 TOPICS I CAN TEACH\n"]
    out.append("  PROGRAMMING CONCEPTS:")
    for key in CONCEPTS:
        out.append(f"    • {key}")
    out.append("\n  PROGRAMMING LANGUAGES:")
    for key in LANGUAGES:
        out.append(f"    • {LANGUAGES[key]['title']}")
    out.append("\n  OTHER TOPICS:")
    for t in ["best practices", "career advice", "project ideas",
              "git & version control", "APIs", "debugging"]:
        out.append(f"    • {t}")
    out.append('\n  Ask about any of these: "what is recursion?" or "teach me Rust"')
    return "\n".join(out)


def respond_compare(lang1: str, lang2: str) -> str:
    comparisons = {
        frozenset(["python", "javascript"]): (
            "Python vs JavaScript:\n"
            "  Python\n"
            "    + Cleaner, more readable syntax\n"
            "    + Excellent for data science & AI (numpy, pandas)\n"
            "    + Great for scripting and automation\n"
            "    - Slower than compiled languages\n"
            "    - Not native in browsers\n\n"
            "  JavaScript\n"
            "    + Runs in every browser natively\n"
            "    + Full-stack with Node.js\n"
            "    + Largest package ecosystem (npm)\n"
            "    - Quirky type coercion (== vs ===)\n"
            "    - Asynchronous complexity\n\n"
            "  Recommendation:\n"
            "    → Python for data, AI, scripting, backend\n"
            "    → JavaScript for web, full-stack, interactive UIs"
        ),
        frozenset(["python", "java"]): (
            "Python vs Java:\n"
            "  Python: fast to write, great for prototyping, slower at runtime\n"
            "  Java:   verbose, but fast, strongly typed, great for enterprise\n\n"
            "  → Choose Python for: data science, scripting, quick projects\n"
            "  → Choose Java for:   Android apps, enterprise software, performance"
        ),
        frozenset(["python", "rust"]): (
            "Python vs Rust:\n"
            "  Python: slow but easy; Rust: fast but complex learning curve\n"
            "  Rust has no garbage collector → predictable, blazing performance\n"
            "  Python is great for prototyping; Rust for systems programming.\n\n"
            "  → Choose Python to learn fast\n"
            "  → Choose Rust when you need maximum performance and memory safety"
        ),
        frozenset(["javascript", "typescript"]): (
            "JavaScript vs TypeScript:\n"
            "  TypeScript IS JavaScript with optional static types.\n"
            "  TypeScript catches bugs at compile time; JS catches them at runtime.\n\n"
            "  → TypeScript is recommended for larger projects and teams.\n"
            "  → JavaScript is fine for small scripts and quick experiments."
        ),
    }

    key = frozenset([lang1, lang2])
    if key in comparisons:
        return "\n  " + comparisons[key].replace("\n", "\n  ")

    l1 = LANGUAGES.get(lang1, {}).get("title", lang1)
    l2 = LANGUAGES.get(lang2, {}).get("title", lang2)
    return (
        f"\n  I can compare these general traits for {l1} vs {l2}:\n"
        f"  Type 'teach me {l1}' or 'teach me {l2}' to learn each in depth,\n"
        f"  then I can help you understand the differences."
    )


def respond_best_practices() -> str:
    return (
        "\n  ✨ CODING BEST PRACTICES\n"
        "  " + "─" * 60 + "\n\n"
        "  NAMING\n"
        "    ✓ Use descriptive names: 'user_age' not 'ua' or 'x'\n"
        "    ✓ Functions should be verbs: get_user(), calculate_total()\n"
        "    ✓ Booleans: is_valid, has_permission, can_edit\n\n"
        "  CODE STRUCTURE\n"
        "    ✓ One function = one task. If it does two things, split it.\n"
        "    ✓ Keep functions short (< 20 lines ideally)\n"
        "    ✓ DRY – Don't Repeat Yourself. If you copy-paste, make a function.\n"
        "    ✓ Write comments for WHY, not WHAT (code shows what)\n\n"
        "  ERROR HANDLING\n"
        "    ✓ Never silently swallow errors (empty except / catch)\n"
        "    ✓ Validate input at the edges of your system\n"
        "    ✓ Fail fast and loudly during development\n\n"
        "  TESTING\n"
        "    ✓ Write tests before or alongside your code\n"
        "    ✓ Test edge cases: empty input, zero, negative numbers\n"
        "    ✓ Automated tests are your safety net for refactoring\n\n"
        "  VERSION CONTROL (GIT)\n"
        "    ✓ Commit often with clear messages\n"
        "    ✓ Never commit secrets/passwords\n"
        "    ✓ Work in feature branches\n\n"
        "  READABILITY\n"
        "    ✓ Readable code > clever code\n"
        "    ✓ Consistent formatting (use a linter/formatter)\n"
        "    ✓ Delete dead code – git history keeps it if you need it"
    )


def respond_career() -> str:
    return (
        "\n  🚀 CAREER ADVICE — WHERE TO START\n"
        "  " + "─" * 60 + "\n\n"
        "  BEGINNER ROADMAP:\n"
        "    1. Pick ONE language first (Python or JavaScript)\n"
        "    2. Learn the fundamentals: variables, loops, functions, OOP\n"
        "    3. Build small projects (todo app, calculator, quiz game)\n"
        "    4. Learn Git + GitHub\n"
        "    5. Learn one web framework (Flask/FastAPI for Python, Express/React for JS)\n"
        "    6. Build a portfolio of 3-5 projects on GitHub\n"
        "    7. Contribute to open source, network, apply!\n\n"
        "  WHICH LANGUAGE TO START WITH?\n"
        "    → Python  – easiest syntax, great for beginners, data science & AI\n"
        "    → JS      – if you want to build websites and apps\n"
        "    → Lua     – if you're building Roblox games\n"
        "    → Java    – if you aim for enterprise/Android development\n\n"
        "  POPULAR CAREER PATHS:\n"
        "    • Frontend Developer  – HTML, CSS, JavaScript, React\n"
        "    • Backend Developer   – Python/Node/Java, databases, APIs\n"
        "    • Full-Stack Dev      – both frontend and backend\n"
        "    • Data Scientist      – Python, SQL, statistics, ML\n"
        "    • Game Developer      – C++, C#, Lua, Unity, Unreal\n"
        "    • DevOps / SRE        – Linux, Docker, Kubernetes, Go\n"
        "    • Mobile Developer    – Swift (iOS) or Kotlin (Android)\n\n"
        "  KEY TRUTH: It's not about the perfect language.\n"
        "  Master the fundamentals in one, then transfer those skills anywhere."
    )


def respond_project_ideas() -> str:
    projects = {
        "Beginner": [
            "Calculator (GUI or CLI)",
            "Number guessing game",
            "To-do list app",
            "Simple quiz app",
            "Unit converter (km to miles, etc.)",
            "Password generator",
            "Mad Libs game",
        ],
        "Intermediate": [
            "Weather app using a public API",
            "Personal expense tracker",
            "Markdown to HTML converter",
            "Simple chat app (WebSocket)",
            "Scrape and analyse news headlines",
            "URL shortener",
            "Clone of Wordle",
        ],
        "Advanced": [
            "REST API with authentication and a database",
            "Real-time multiplayer game",
            "Your own programming language (interpreter)",
            "Neural network from scratch (numpy only)",
            "Code editor in the terminal (like nano)",
            "Distributed key-value store",
            "Compiler or transpiler",
        ],
    }
    out = ["\n  🏗️  PROJECT IDEAS\n"]
    for level, ideas in projects.items():
        out.append(f"  {level.upper()}:")
        for idea in ideas:
            out.append(f"    → {idea}")
        out.append("")
    out.append("  Tip: The best project is the one you're motivated to finish.")
    out.append("  Start small, ship something, then iterate!")
    return "\n".join(out)


def respond_unknown(text: str) -> str:
    suggestions = [
        "teach me Python",
        "what is a variable?",
        "give me an exercise",
        "quiz me on loops",
        "explain recursion",
        "compare Python vs JavaScript",
        "career advice",
    ]
    s = random.choice(suggestions)
    return (
        f"\n  I'm not sure I understood that. Here are some things you can ask:\n"
        f"    • 'teach me <language>'    (Python, JS, Lua, Java, Rust, Go...)\n"
        f"    • 'what is <concept>?'     (loop, function, class, recursion...)\n"
        f"    • 'exercise'               (get a coding challenge)\n"
        f"    • 'quiz me on <topic>'\n"
        f"    • 'topics'                 (see everything I can teach)\n"
        f"    • 'help'                   (full command list)\n\n"
        f"  Or try: '{s}'"
    )


def respond_analyze_code(text: str) -> str:
    code_match = re.search(r"```(?:\w+)?\n?([\s\S]+?)```", text)
    if code_match:
        code = code_match.group(1).strip()
        analysis = _analyze_snippet(code)
        return f"\n  🔍 CODE ANALYSIS\n  {'─'*60}\n\n{analysis}"
    return (
        "\n  To analyse your code, paste it with triple backticks:\n\n"
        "  ```python\n"
        "  def hello():\n"
        "      print('world')\n"
        "  ```\n\n"
        "  Or describe what your code does and what's going wrong."
    )


def _analyze_snippet(code: str) -> str:
    lines = code.split("\n")
    observations = []

    # Detect language
    lang = "unknown"
    if re.search(r"\bdef \w+|import |print\(", code):
        lang = "Python"
    elif re.search(r"\bfunction\b|\bconsole\.log\b|const |let |var ", code):
        lang = "JavaScript"
    elif re.search(r"\blocal \w+|print\(|end\b", code):
        lang = "Lua"
    elif re.search(r"\bpublic static|System\.out|class \w+.*\{", code):
        lang = "Java"

    observations.append(f"  Detected language: {lang}")
    observations.append(f"  Lines of code:     {len(lines)}")

    # Python-specific checks
    if lang == "Python":
        if "except:" in code or "except Exception:" in code:
            observations.append("  ⚠  Bare 'except' catches ALL errors — be specific (e.g., except ValueError:)")
        if re.search(r"for .+ in range\(len\(", code):
            observations.append("  💡 Use 'for i, v in enumerate(list)' instead of 'range(len(list))'")
        if re.search(r"== None", code):
            observations.append("  💡 Use 'is None' instead of '== None'")
        if re.search(r"\bprint\b.*\bfor\b|\bfor\b.*\bprint\b", code):
            observations.append("  💡 Consider a list comprehension for collection building")
        if not re.search(r"def \w+\(.*\).*->|:\s*#", code) and "def " in code:
            observations.append("  💡 Consider adding type hints: def fn(x: int) -> str:")

    # JS-specific checks
    if lang == "JavaScript":
        if "var " in code:
            observations.append("  ⚠  Avoid 'var' — use 'const' or 'let' instead")
        if re.search(r"== [^=]|[^=!<>]== ", code):
            observations.append("  ⚠  Use '===' (strict equality) instead of '=='")
        if "console.log" in code and code.count("console.log") > 3:
            observations.append("  💡 Many console.log calls — consider a proper logger or debugger")

    # Lua-specific checks
    if lang == "Lua":
        if re.search(r"(?<!\blocal\b)\s+\w+ = ", code) and "local" not in code:
            observations.append("  ⚠  Variables without 'local' are globals — add 'local' keyword")
        if "wait(" in code:
            observations.append("  💡 In Roblox, prefer task.wait() over wait() for accuracy")

    # Universal checks
    if len([l for l in lines if len(l) > 100]) > 0:
        observations.append("  💡 Some lines are very long (>100 chars) — consider breaking them up")

    fn_count = len(re.findall(r"\bdef |\bfunction |\blocal function ", code))
    if fn_count > 0:
        observations.append(f"  ✓ Found {fn_count} function(s) — good use of code organisation")

    return "\n".join(observations) + "\n\n  Paste the code with a description of what it should do for more specific advice."

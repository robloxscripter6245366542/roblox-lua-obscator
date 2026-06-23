"""Core Nano AI session manager – handles all routing, state, memory."""

import random
import re
from datetime import datetime

from .brain import (
    classify_intent, _extract_concept, _extract_language,
    respond_greet, respond_help, respond_concept, respond_language,
    respond_topics, respond_compare, respond_best_practices,
    respond_career, respond_project_ideas, respond_unknown,
    respond_analyze_code,
    THANKS_RESPONSES, FAREWELL,
)
from .knowledge.exercises_kb import EXERCISES, QUIZZES
from .knowledge.languages_kb  import LANGUAGES, LANG_ALIASES
from .knowledge.general_kb    import CONCEPTS, ALIASES
from .generator  import generate
from .fetcher    import fetch_url, web_search_ddg
from .filesystem import read_file, write_file, list_dir, analyze_file
from .memory     import load_memory, save_memory, log_exchange, learn_correction, build_user_profile


def _norm(text: str) -> str:
    return re.sub(r"\s+", " ", text.strip().lower())


def _extract_lang_pair(text: str):
    t = _norm(text)
    found = []
    for alias, key in LANG_ALIASES.items():
        if re.search(r'\b' + re.escape(alias) + r'\b', t):
            if key not in found:
                found.append(key)
    for key in LANGUAGES:
        if re.search(r'\b' + re.escape(key) + r'\b', t):
            if key not in found:
                found.append(key)
    return found[:2] if len(found) >= 2 else None


def _extract_url(text: str) -> str | None:
    m = re.search(r'https?://\S+', text)
    return m.group(0) if m else None


def _extract_path(text: str) -> str | None:
    m = re.search(r'[\'"]?([~/.]?[\w./\\-]+\.\w{1,5})[\'"]?', text)
    if m:
        p = m.group(1)
        if any(p.endswith(ext) for ext in ['.py','.js','.ts','.lua','.java','.cpp','.rs','.go','.html','.css','.sql','.json','.txt','.md']):
            return p
    return None


# ─── Session ─────────────────────────────────────────────────────────────────

class Session:
    def __init__(self):
        self.start_time       = datetime.now()
        self.questions_asked  = 0
        self.correct_answers  = 0
        self.exercises_done   = 0
        self.topics_covered   = set()
        self.xp               = 0
        self.current_exercise = None
        self.current_quiz     = None
        self.quiz_index       = 0

    def award_xp(self, amount: int) -> str:
        prev = self._level()
        self.xp += amount
        after = self._level()
        msg = f"  +{amount} XP!"
        if after > prev:
            msg += f"  🎉 LEVEL UP! You are now Level {after} — {self._level_name()}!"
        return msg

    def _level(self) -> int:
        for i, t in enumerate(reversed([0,50,150,350,700,1200,2000])):
            if self.xp >= t:
                return 7 - i
        return 1

    def _level_name(self) -> str:
        return {1:"Novice",2:"Apprentice",3:"Coder",4:"Developer",
                5:"Engineer",6:"Architect",7:"Wizard"}.get(self._level(),"Master")

    def _next_xp(self) -> int:
        thresholds = [0,50,150,350,700,1200,2000]
        lvl = self._level()
        return thresholds[lvl] - self.xp if lvl < len(thresholds) else 0

    def progress_report(self) -> str:
        elapsed = datetime.now() - self.start_time
        mins = int(elapsed.total_seconds() // 60)
        secs = int(elapsed.total_seconds() % 60)
        acc  = (f"{self.correct_answers}/{self.questions_asked} "
                f"({100*self.correct_answers//max(self.questions_asked,1)}%)"
                if self.questions_asked else "No quizzes yet")
        return (
            f"\n  📊 NANO AI — YOUR PROGRESS\n"
            f"  {'─'*50}\n"
            f"  Level:      {self._level()} — {self._level_name()}\n"
            f"  XP:         {self.xp}  (need {self._next_xp()} more for next level)\n"
            f"  Session:    {mins}m {secs}s\n"
            f"  Topics:     {len(self.topics_covered)}\n"
            f"  Exercises:  {self.exercises_done}\n"
            f"  Quiz score: {acc}\n"
        )


# ─── Tutor ────────────────────────────────────────────────────────────────────

class Tutor:
    def __init__(self):
        self.session = Session()
        self.memory  = load_memory()
        self.memory["sessions"] = self.memory.get("sessions", 0) + 1

    def respond(self, user_input: str) -> tuple[str, bool]:
        text   = user_input.strip()
        intent = classify_intent(text)
        log_exchange(text, "...")

        # ── Goodbye ─────────────────────────────────────────────
        if intent == "goodbye":
            self.memory["total_xp"] = self.memory.get("total_xp", 0) + self.session.xp
            self.memory["topics_mastered"] = list(
                set(self.memory.get("topics_mastered", [])) | self.session.topics_covered
            )
            save_memory(self.memory)
            report = self.session.progress_report()
            return report + "\n  " + random.choice(FAREWELL), True

        # ── Quiz in progress (highest priority) ─────────────────
        if self.session.current_quiz is not None and intent not in ("goodbye","quiz","exercise"):
            return self._handle_quiz_answer(text), False

        # ── Exercise hint/solution ───────────────────────────────
        if self.session.current_exercise and intent in ("hint","solution"):
            return (self._give_hint() if intent=="hint" else self._give_solution()), False

        # ── Route ────────────────────────────────────────────────
        if intent == "greet":
            name = self.memory.get("user_name")
            base = respond_greet()
            if name:
                base = f"  Welcome back, {name}! {base.strip()}"
            return base, False

        if intent == "help":
            return respond_help(), False

        if intent == "topics":
            return respond_topics(), False

        if intent == "thanks":
            return "  " + random.choice(THANKS_RESPONSES), False

        if intent == "progress":
            return self.session.progress_report(), False

        if intent == "best_practices":
            return respond_best_practices(), False

        if intent == "career":
            return respond_career(), False

        if intent == "project_ideas":
            return respond_project_ideas(), False

        if intent == "analyze_code":
            return respond_analyze_code(text), False

        if intent == "compare_languages":
            pair = _extract_lang_pair(text)
            if pair and len(pair) == 2:
                return respond_compare(pair[0], pair[1]), False
            return "\n  Name two languages to compare, e.g. 'compare Python vs JavaScript'", False

        if intent == "generate":
            resp = generate(text)
            self.session.xp += 5
            return resp, False

        if intent == "fetch":
            return self._do_fetch(text), False

        if intent == "read_file":
            path = _extract_path(text)
            if path:
                return read_file(path), False
            return "\n  Which file? e.g. 'read mycode.py'", False

        if intent == "write_file":
            return "\n  To write a file, tell me:\n  'write [filename] with [content or language]'\n  Or say: 'generate a Flask API' then 'save it to app.py'", False

        if intent == "list_files":
            t = _norm(text)
            m = re.search(r'(?:in|of|inside|from|at)\s+([\w./~]+)', t)
            path = m.group(1) if m else "."
            return list_dir(path), False

        if intent == "profile":
            t = _norm(text)
            m = re.search(r"my name is (\w+)", t)
            if m:
                name = m.group(1).title()
                self.memory["user_name"] = name
                save_memory(self.memory)
                return f"\n  Nice to meet you, {name}! I'll remember that.", False
            return build_user_profile(self.memory), False

        if intent == "correct":
            self.memory = learn_correction("previous response", text, self.memory)
            save_memory(self.memory)
            return "\n  Got it — thanks for the correction! I've noted that to improve.", False

        if intent == "learn_concept":
            concept_key, concept = _extract_concept(text)
            if concept:
                self.session.topics_covered.add(concept_key)
                xp = self.session.award_xp(10)
                return respond_concept(concept_key, concept) + f"\n\n{xp}", False
            lang_key, lang = _extract_language(text)
            if lang:
                self.session.topics_covered.add(lang_key)
                xp = self.session.award_xp(15)
                return respond_language(lang_key, lang) + f"\n\n{xp}", False
            return self._suggest_concept(text), False

        if intent == "learn_language":
            lang_key, lang = _extract_language(text)
            if lang:
                self.session.topics_covered.add(lang_key)
                self.memory["preferred_language"] = lang_key
                save_memory(self.memory)
                xp = self.session.award_xp(15)
                return respond_language(lang_key, lang) + f"\n\n{xp}", False
            return "\n  Which language? Options: " + ", ".join(LANGUAGES.keys()), False

        if intent == "exercise":
            return self._start_exercise(text), False

        if intent == "quiz":
            return self._start_quiz(text), False

        if intent == "hint":
            if self.session.current_exercise:
                return self._give_hint(), False
            return "\n  No active exercise. Type 'exercise' to start one!", False

        if intent == "solution":
            if self.session.current_exercise:
                return self._give_solution(), False
            return "\n  No active exercise. Type 'exercise' to start!", False

        # ── Fallback concept/language lookup ────────────────────
        concept_key, concept = _extract_concept(text)
        if concept:
            self.session.topics_covered.add(concept_key)
            xp = self.session.award_xp(10)
            return respond_concept(concept_key, concept) + f"\n\n{xp}", False

        lang_key, lang = _extract_language(text)
        if lang:
            self.session.topics_covered.add(lang_key)
            xp = self.session.award_xp(15)
            return respond_language(lang_key, lang) + f"\n\n{xp}", False

        return respond_unknown(text), False

    # ── WebFetch ──────────────────────────────────────────────────────────────

    def _do_fetch(self, text: str) -> str:
        url = _extract_url(text)
        if url:
            result = fetch_url(url)
            if result["ok"]:
                return (
                    f"\n  🌐 WEBFETCH — {result['url']}\n"
                    f"  {'─'*60}\n\n"
                    + "\n".join("  " + l for l in result["content"].split("\n")[:60])
                    + "\n\n  (truncated – content fetched successfully)"
                )
            return f"\n  ❌ Fetch failed: {result['error']}"

        # Search query
        t = _norm(text)
        query = re.sub(r'\b(fetch|search|look up|find|google|browse|web search|search the web|online)\b', '', t).strip()
        if not query:
            return "\n  What do you want to search for? e.g. 'search Python asyncio tutorial'"
        results = web_search_ddg(query, max_results=4)
        out = [f"\n  🔍 WEB SEARCH — '{query}'\n  {'─'*60}\n"]
        for i, r in enumerate(results, 1):
            out.append(f"  {i}. {r['title'][:70]}")
            if r.get("url"):
                out.append(f"     {r['url']}")
            out.append(f"     {r['snippet'][:200]}")
            out.append("")
        out.append("  Type 'fetch <url>' to open any of these links in full.")
        return "\n".join(out)

    # ── Exercises ─────────────────────────────────────────────────────────────

    def _start_exercise(self, text: str) -> str:
        t = _norm(text)
        if "advanced" in t or "hard" in t:
            pool = EXERCISES["advanced"]
            lvl  = "advanced"
        elif "intermediate" in t or "medium" in t:
            pool = EXERCISES["intermediate"]
            lvl  = "intermediate"
        elif "beginner" in t or "easy" in t:
            pool = EXERCISES["beginner"]
            lvl  = "beginner"
        else:
            pool, lvl = random.choice([
                (EXERCISES["beginner"],     "beginner"),
                (EXERCISES["intermediate"], "intermediate"),
                (EXERCISES["advanced"],     "advanced"),
            ])
        ex = random.choice(pool)
        self.session.current_exercise = ex
        return (
            f"\n  🏋️  CODING EXERCISE [{lvl.upper()}]\n"
            f"  {'─'*60}\n\n"
            f"  {ex['title']}\n\n"
            f"  Task: {ex['description']}\n\n"
            f"  Commands: 'hint' | 'solution' | 'exercise' (new one)\n\n"
            f"  Write your solution and share it, or type 'solution'!"
        )

    def _give_hint(self) -> str:
        ex = self.session.current_exercise
        return f"\n  💡 HINT: {ex['hint']}" if ex else "\n  No active exercise."

    def _give_solution(self) -> str:
        ex = self.session.current_exercise
        if not ex:
            return "\n  No active exercise."
        self.session.exercises_done += 1
        xp = self.session.award_xp(20)
        self.session.current_exercise = None
        out = [f"\n  ✅ SOLUTION — {ex['title']}\n", f"  {'─'*60}\n"]
        for label, key in [("Python","solution_python"),("JavaScript","solution_js"),("Lua","solution_lua")]:
            if key in ex:
                out.append(f"  {label}:")
                for line in ex[key].split("\n"):
                    out.append(f"    {line}")
                out.append("")
        out.append(xp)
        out.append("  Type 'exercise' for another challenge!")
        return "\n".join(out)

    # ── Quiz ──────────────────────────────────────────────────────────────────

    def _start_quiz(self, text: str) -> str:
        t = _norm(text)
        topic = next((k for k in QUIZZES if k in t), random.choice(list(QUIZZES.keys())))
        questions = QUIZZES[topic][:]
        random.shuffle(questions)
        self.session.current_quiz  = {"topic": topic, "questions": questions}
        self.session.quiz_index    = 0
        self.session.questions_asked += len(questions)
        return self._show_quiz_question()

    def _show_quiz_question(self) -> str:
        quiz = self.session.current_quiz
        idx  = self.session.quiz_index
        if idx >= len(quiz["questions"]):
            return self._end_quiz()
        q    = quiz["questions"][idx]
        opts = q.get("options", [])
        out  = [
            f"\n  ❓ QUIZ — {quiz['topic'].upper()} "
            f"({idx+1}/{len(quiz['questions'])})\n",
            f"  {'─'*60}\n",
            f"  {q['q']}\n",
        ]
        for i, opt in enumerate(opts):
            out.append(f"    {chr(65+i)}) {opt}")
        out.append("\n  Type A, B, C, or D:")
        return "\n".join(out)

    def _handle_quiz_answer(self, text: str) -> str:
        quiz = self.session.current_quiz
        idx  = self.session.quiz_index
        q    = quiz["questions"][idx]
        opts = q.get("options", [])
        t    = text.strip().upper()
        answer_text = text.strip().lower()
        if len(t) == 1 and t in "ABCD" and opts:
            letter_idx = ord(t) - ord("A")
            if letter_idx < len(opts):
                answer_text = opts[letter_idx].lower()
        correct    = q["answer"].lower()
        is_correct = answer_text == correct or correct in answer_text or answer_text in correct
        if is_correct:
            self.session.correct_answers += 1
            xp = self.session.award_xp(15)
            feedback = f"  ✅ Correct! {xp}\n  {q.get('explanation','')}"
        else:
            feedback = f"  ❌ Not quite. Answer: {q['answer']}\n  {q.get('explanation','')}"
        self.session.quiz_index += 1
        if self.session.quiz_index >= len(quiz["questions"]):
            return feedback + "\n" + self._end_quiz()
        return feedback + "\n" + self._show_quiz_question()

    def _end_quiz(self) -> str:
        quiz    = self.session.current_quiz
        correct = self.session.correct_answers
        total   = len(quiz["questions"])
        self.session.current_quiz = None
        pct  = int(100 * correct / max(total, 1))
        star = "🏆 Perfect!" if pct==100 else ("🎉 Great!" if pct>=70 else ("👍 Keep going!" if pct>=40 else "📚 Study more!"))
        return (
            f"\n  QUIZ COMPLETE — {quiz['topic'].upper()}\n"
            f"  Score: {correct}/{total} ({pct}%)  {star}\n\n"
            f"  Type 'quiz me on {quiz['topic']}' to retry!"
        )

    def _suggest_concept(self, text: str) -> str:
        words = set(_norm(text).split())
        scored = sorted(
            ((len(words & set(k.split())), k) for k in CONCEPTS),
            reverse=True
        )
        suggestions = [k for _, k in scored[:3] if _ > 0]
        if suggestions:
            s = ", ".join(f"'{k}'" for k in suggestions)
            return f"\n  Did you mean: {s}?\n  Or type 'topics' to see everything."
        return respond_unknown(text)

#!/usr/bin/env python3
"""Regenerate the question-bank assets bundled with the app.

Requires the fs-exam-prep engine (Phase 1 repo):

    pip install -e ../fs-exam-prep

Each bank covers all 48 topics x N questions with a distinct seed, so every
bank is a fresh exam. The app lists them in BankRepository.availableBanks.

Usage:
    python3 tools/generate_banks.py [--n 10] [--seeds 7 42]
"""
import argparse
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "..", "fs-exam-prep", "src"))

from fs_quiz.engine import QuizEngine  # noqa: E402


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--n", type=int, default=10, help="questions per topic")
    p.add_argument("--seeds", type=int, nargs="+", default=[7, 42])
    args = p.parse_args()

    out_dir = os.path.join(os.path.dirname(__file__), "..", "assets", "banks")
    os.makedirs(out_dir, exist_ok=True)

    eng = QuizEngine()
    for seed in args.seeds:
        bank = eng.generate_bank(n_per_topic=args.n, seed=seed)
        path = os.path.join(out_dir, f"bank-seed-{seed}.json")
        eng.export_bank(bank, path)
        print(f"seed {seed}: {len(bank)} questions -> {path}")
    print("Done. If you added a seed, list it in BankRepository.availableBanks.")


if __name__ == "__main__":
    main()

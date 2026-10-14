#!/usr/bin/env python3
# =============================================================================
# check.py — Prove authenticated generation, tools, and log analysis work.
# Optional long-context retrieval and streaming throughput checks save evidence.
# Copyright (c) 2026 Temesgen Ataro <ataro.temesgen@gmail.com>
# SPDX-License-Identifier: Apache-2.0
# =============================================================================
import argparse
import json
import os
import time
import urllib.error
import urllib.request
from pathlib import Path


def request(path, payload=None, authenticated=True):
    headers = {"Content-Type": "application/json"}
    if authenticated:
        headers["Authorization"] = "Bearer " + Path(os.environ["GLM_API_KEY_FILE"]).read_text().strip()
    req = urllib.request.Request(os.environ["GLM_BASE_URL"].rstrip("/") + path,
                                 data=None if payload is None else json.dumps(payload).encode(), headers=headers)
    return urllib.request.urlopen(req, timeout=1800)


def chat(content, **kwargs):
    payload = {"model": "glm-5.3-flash", "messages": [{"role": "user", "content": content}],
               "max_tokens": 2048, "temperature": 0,
               "chat_template_kwargs": {"reasoning_effort": "max", "clear_thinking": False}}
    payload.update(kwargs)
    started = time.monotonic()
    with request("/chat/completions", payload) as response:
        result = json.load(response)
    result["elapsed_seconds"] = round(time.monotonic() - started, 3)
    return result


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--long", action="store_true")
    parser.add_argument("--bench", action="store_true")
    parser.add_argument("--ready", action="store_true", help="check authenticated model identity/capacity only")
    args = parser.parse_args()
    results = {}
    try:
        request("/models", authenticated=False).close()
        raise AssertionError("anonymous model access was permitted")
    except urllib.error.HTTPError as error:
        assert error.code == 401, f"expected 401, got {error.code}"
    with request("/models") as response:
        models = json.load(response)["data"]
    assert any(m["id"] == "glm-5.3-flash" for m in models)
    model = next(m for m in models if m["id"] == "glm-5.3-flash")
    assert model.get("max_model_len") == 262144, model
    results["auth_and_model"] = "pass"
    if args.ready:
        print("GLM_READY context=262144 auth=pass")
        return
    print("PASS authentication and native context", flush=True)
    result = chat("Reply with exactly GLM_ALIVE")
    assert result["choices"][0]["message"]["content"].strip() == "GLM_ALIVE", result
    results["proof_of_life"] = result
    print("PASS generation", flush=True)
    tool = {"type": "function", "function": {"name": "read_log_window", "description": "Read logs for an interval",
            "parameters": {"type": "object", "properties": {"seconds": {"type": "integer"}}, "required": ["seconds"]}}}
    result = chat("Call read_log_window with seconds=60. Do not answer from memory.", tools=[tool], tool_choice="auto")
    calls = result["choices"][0]["message"].get("tool_calls")
    assert calls and calls[0]["function"]["name"] == "read_log_window", result
    assert json.loads(calls[0]["function"]["arguments"])["seconds"] == 60, result
    results["tool_call"] = result
    print("PASS tool call JSON", flush=True)
    assistant = result["choices"][0]["message"]
    replay = {"role": "assistant", "content": assistant.get("content"), "tool_calls": calls}
    reasoning = assistant.get("reasoning_content") or assistant.get("reasoning")
    if reasoning:
        replay["reasoning_content"] = reasoning
    result = chat("", tools=[tool], messages=[
        {"role": "user", "content": "Read the last 60 seconds of logs, then report the sample count as an integer only."},
        replay,
        {"role": "tool", "tool_call_id": calls[0]["id"], "content": '{"sample_count":4096}'}])
    assert result["choices"][0]["message"]["content"].strip() == "4096", result
    results["tool_round_trip"] = result
    print("PASS tool replay", flush=True)
    result = chat('Analyze these samples: amplitude=[1,2,3,4], timestamps=[0,1,2,3] seconds. '
                  'Return only JSON with mean, rms (at least 5 decimal places), and sample_rate_hz.')
    content = result["choices"][0]["message"]["content"].strip()
    if content.startswith("```"):
        content = "\n".join(content.splitlines()[1:-1])
    analysis = json.loads(content)
    assert analysis["mean"] == 2.5 and abs(analysis["rms"] - 2.7386128) < 1e-4
    assert analysis["sample_rate_hz"] == 1
    results["numerical_analysis"] = result
    print("PASS numerical analysis", flush=True)
    if args.long:
        marker = "MAGNOLIA-5831-SPECTRUM"
        result = chat(" x" * 120000 + "\nRemember the marker: " + marker + "\n" + " x" * 120000
                      + "\nReply with only the exact marker.", max_tokens=4096)
        assert result["usage"]["prompt_tokens"] >= 200000, result["usage"]
        assert result["choices"][0]["message"]["content"].strip() == marker, result
        results["long_context"] = result
        print(f'PASS long context: {result["usage"]["prompt_tokens"]} prompt tokens', flush=True)
    if args.bench:
        payload = {"model": "glm-5.3-flash", "messages": [{"role": "user", "content": "Write a detailed Python DSP tutorial with runnable examples."}],
                   "stream": True, "stream_options": {"include_usage": True}, "max_tokens": 512,
                   "chat_template_kwargs": {"reasoning_effort": "max"}}
        start = time.monotonic()
        first = None
        usage = None
        with request("/chat/completions", payload) as response:
            for line in response:
                if not line.startswith(b"data: ") or line.strip() == b"data: [DONE]":
                    continue
                event = json.loads(line[6:])
                for choice in event.get("choices", []):
                    delta = choice.get("delta", {})
                    if first is None and (delta.get("content") or delta.get("reasoning_content") or delta.get("reasoning")):
                        first = time.monotonic()
                usage = event.get("usage") or usage
        elapsed = time.monotonic() - start
        assert usage and first is not None, "missing streaming tokens/usage"
        results["benchmark"] = {"ttft_seconds": first - start, "elapsed_seconds": elapsed,
                                 "output_tokens_per_second": usage["completion_tokens"] / elapsed, "usage": usage}
        print("BENCH " + json.dumps(results["benchmark"]), flush=True)
    Path("results").mkdir(exist_ok=True)
    output = Path("results") / (time.strftime("%Y%m%d-%H%M%S") + ".json")
    output.write_text(json.dumps(results, indent=2))
    print(json.dumps({"checks": list(results), "evidence": str(output)}, indent=2))


if __name__ == "__main__":
    main()

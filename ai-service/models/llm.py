"""
models/llm.py
--------------
LLM interface for the narration stage (stage_6_narration).
This is the ONLY component that uses an LLM.

CRITICAL RULE: The LLM receives structured AnalysisResult data only.
It NEVER receives raw OCR text, bill images, or numeric data it is
expected to perform arithmetic on. All math is done in stage_5 first.

Not wired in Phase 1. Phase 6: implement with openai / anthropic SDK.
"""

from __future__ import annotations

from abc import ABC, abstractmethod


class LlmModel(ABC):
    @abstractmethod
    def narrate(self, prompt: str, max_tokens: int = 60) -> str:
        """Return exactly one sentence."""
        ...


class NarrationStub(LlmModel):
    """
    Phase 1 stub — returns a template sentence.
    Replace with OpenAI / Anthropic call in Phase 6.
    """

    def narrate(self, prompt: str, max_tokens: int = 60) -> str:
        return "Normal for this time of year. Nothing looks unusual."


# TODO Phase 6: implement OpenAiNarrationModel and AnthropicNarrationModel
# class OpenAiNarrationModel(LlmModel):
#     def __init__(self, model: str = "gpt-4o-mini") -> None:
#         import openai
#         self._client = openai.OpenAI()
#         self._model = model
#
#     def narrate(self, prompt: str, max_tokens: int = 60) -> str:
#         resp = self._client.chat.completions.create(
#             model=self._model,
#             messages=[{"role": "user", "content": prompt}],
#             max_tokens=max_tokens,
#         )
#         return resp.choices[0].message.content.strip()

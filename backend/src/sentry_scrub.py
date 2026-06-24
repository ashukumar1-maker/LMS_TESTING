"""Sentry event scrubbing.

Kept out of ``server.py`` so that critical-path file stays minimal. We keep
``send_default_pii=True`` (PII is wanted for debugging) and keep cookies, but
scrub auth headers so bearer tokens / API keys never reach Sentry.
(SOC 2 — Confidentiality.)
"""

from __future__ import annotations

from typing import TypeGuard

from sentry_sdk.types import Event, Hint

# Header names (lower-cased) whose values are redacted from Sentry events.
_SENSITIVE_HEADERS = {"authorization", "x-api-key"}


def _is_str_keyed_dict(value: object) -> TypeGuard[dict[str, object]]:
    """Narrow a third-party ``object`` to a header-style dict at the boundary.

    Sentry types ``Event["request"]`` as ``dict[str, object]``, so headers
    arrive as ``object`` and a plain ``isinstance`` only narrows to an untyped
    dict. This guard narrows to the documented HTTP-header shape without a
    type-checker bypass (same boundary concern as
    health_checks/check_database_access.py).

    Args:
        value: The unverified header payload from the Sentry event.

    Returns:
        True when ``value`` is a dict, narrowing it to ``dict[str, object]``.
    """
    return isinstance(value, dict)


def scrub_sentry_auth_headers(event: Event, _hint: Hint) -> Event:
    """Redact auth headers from an outgoing Sentry event.

    Wired into ``sentry_sdk.init`` as both ``before_send`` and
    ``before_send_transaction``.

    Args:
        event: The Sentry event payload about to be sent.
        _hint: Sentry's before_send / before_send_transaction hint (unused).

    Returns:
        The event with any sensitive request headers replaced by "[Filtered]".
    """
    request = event.get("request")
    if request is not None:
        raw_headers = request.get("headers")
        if _is_str_keyed_dict(raw_headers):
            for name in list(raw_headers):
                if name.lower() in _SENSITIVE_HEADERS:
                    raw_headers[name] = "[Filtered]"
    return event

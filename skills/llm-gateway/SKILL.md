---
name: llm-gateway
description: A unified API gateway for interacting with multiple LLM providers through an OpenAI-compatible interface.
---

# Ciridae LLM Gateway - External Integration Guide

A unified API gateway for interacting with multiple LLM providers through an OpenAI-compatible interface. This document covers everything you need to integrate with the LLM Gateway from external applications.

## Quick Start

The Gateway uses the OpenAI SDK as the universal interface. Simply point your OpenAI client at the Gateway:

```python
from openai import OpenAI

client = OpenAI(
    api_key="your-gateway-api-key",
    base_url="https://api.llmgateway.ciridae.app",
)
```

All interactions use either:
- **Chat Completions API** (`/chat/completions`) - Standard chat interface
- **Responses API** (`/responses`) - Enhanced interface with hosted tools

---

## Supported Providers & Models

The Gateway routes requests to multiple providers. Specify models using the `provider/model-name` format:

### Direct Model Access

| Provider | Example Models |
|----------|---------------|
| **OpenAI** | `openai/gpt-4o`, `openai/gpt-4.1`, `openai/gpt-4.1-mini`, `openai/gpt-4o-mini` |
| **Anthropic** | `anthropic/claude-sonnet-4-20250514`, `anthropic/claude-3-5-sonnet-20241022`, `anthropic/claude-3-7-sonnet-20250219` |
| **Google** | `gemini/gemini-2.5-pro`, `gemini/gemini-2.0-flash-001`, `gemini/gemini-1.5-pro-002` |

### Model Routers (Recommended)

Model routers provide automatic load balancing, rate limit management, and fallback chains across multiple providers:

| Router | Description | Underlying Models |
|--------|-------------|-------------------|
| `fast-production` | Optimized for speed and cost | Gemini 2.0 Flash, GPT-4.1-mini, Gemini 1.5 Flash, Claude 3.5 Haiku, GPT-4o-mini |
| `strong-production` | Optimized for quality | Gemini 2.5 Pro, GPT-4.1, Claude Sonnet 4 |
| `claude-3-5-sonnet` | Load-balanced Claude 3.5 Sonnet | Anthropic API + AWS Bedrock |
| `claude-3-7-sonnet` | Load-balanced Claude 3.7 Sonnet | Anthropic API + AWS Bedrock |
| `claude-sonnet-4-20250514` | Load-balanced Claude 4 Sonnet | Anthropic API + AWS Bedrock |
| `claude-sonnet-4-5` | Load-balanced Claude Sonnet 4.5 | Anthropic API + AWS Bedrock |
| `claude-haiku-4-5` | Load-balanced Claude Haiku 4.5 | Anthropic API + AWS Bedrock |

**Benefits of routers:**
- Automatic failover when a provider returns errors
- Rate-limit aware routing spreads load across providers
- Higher effective throughput than single-provider access

---

## Chat Completions API

Standard OpenAI-compatible chat completions endpoint.

### Basic Usage

```python
response = client.chat.completions.create(
    model="strong-production",
    messages=[
        {"role": "system", "content": "You are a helpful assistant."},
        {"role": "user", "content": "Hello!"}
    ],
)

print(response.choices[0].message.content)
```

### Streaming

```python
stream = client.chat.completions.create(
    model="fast-production",
    messages=[{"role": "user", "content": "Tell me a story"}],
    stream=True,
)

for chunk in stream:
    if chunk.choices[0].delta.content:
        print(chunk.choices[0].delta.content, end="")
```

### Structured Outputs

Use `response_format` for guaranteed JSON output:

```python
from pydantic import BaseModel

class CalendarEvent(BaseModel):
    name: str
    date: str
    participants: list[str]

completion = client.beta.chat.completions.parse(
    model="strong-production",
    messages=[
        {"role": "system", "content": "Extract the event information."},
        {"role": "user", "content": "Alice and Bob are going to a science fair on Friday."},
    ],
    response_format=CalendarEvent,
)

event = completion.choices[0].message.parsed
print(f"Event: {event.name} on {event.date}")
```

Or use JSON mode directly:

```python
response = client.chat.completions.create(
    model="fast-production",
    messages=[{"role": "user", "content": "List 3 colors as JSON"}],
    response_format={"type": "json_object"},
)
```

### Reasoning Effort

Control the depth of model reasoning (supported by compatible models):

```python
response = client.chat.completions.create(
    model="strong-production",
    messages=[{"role": "user", "content": "Solve this complex problem..."}],
    reasoning_effort="high",  # Options: "low", "medium", "high"
)
```

### Image Inputs

Pass images via base64 encoding or URL:

```python
import base64

def encode_image(image_path: str) -> str:
    with open(image_path, "rb") as f:
        return base64.b64encode(f.read()).decode("utf-8")

# Base64 encoded image
response = client.chat.completions.create(
    model="fast-production",
    messages=[
        {
            "role": "user",
            "content": [
                {"type": "text", "text": "What is in this image?"},
                {
                    "type": "image_url",
                    "image_url": {
                        "url": f"data:image/jpeg;base64,{encode_image('photo.jpg')}"
                    },
                },
            ],
        }
    ],
)

# Or via URL
response = client.chat.completions.create(
    model="fast-production",
    messages=[
        {
            "role": "user",
            "content": [
                {"type": "text", "text": "Describe this image"},
                {
                    "type": "image_url",
                    "image_url": {"url": "https://example.com/image.jpg"},
                },
            ],
        }
    ],
)
```

### Tool Use / Function Calling

```python
tools = [
    {
        "type": "function",
        "function": {
            "name": "get_weather",
            "description": "Get the current weather in a location",
            "parameters": {
                "type": "object",
                "properties": {
                    "location": {
                        "type": "string",
                        "description": "City name"
                    }
                },
                "required": ["location"]
            }
        }
    }
]

response = client.chat.completions.create(
    model="fast-production",
    messages=[{"role": "user", "content": "What's the weather in Tokyo?"}],
    tools=tools,
)

# Handle tool calls in response.choices[0].message.tool_calls
```

---

## Responses API

OpenAI's enhanced Responses API with support for hosted tools that execute server-side.

### Basic Usage

```python
response = client.responses.create(
    model="fast-production",
    input=[{"role": "user", "content": "Hello!"}],
)

print(response.output_text)
```

### With System Instructions

```python
response = client.responses.create(
    model="strong-production",
    instructions="You are a professional technical writer.",
    input=[{"role": "user", "content": "Explain async/await"}],
)
```

### Reasoning Control

```python
response = client.responses.create(
    model="strong-production",
    input=[{"role": "user", "content": "Complex reasoning task..."}],
    reasoning={"effort": "high"},  # or "low", "medium"
)
```

### Hosted Tools

Hosted tools execute directly on the Gateway, eliminating round-trips:

#### URL to Markdown

Fetch and convert web pages to markdown:

```python
response = client.responses.create(
    model="fast-production",
    tools=[{"type": "url_to_markdown"}],
    input=[{
        "role": "user",
        "content": "Summarize this article: https://example.com/article"
    }],
)
```

#### Internet Search

Search the web using Exa:

```python
response = client.responses.create(
    model="fast-production",
    tools=[{"type": "internet_search"}],
    input=[{
        "role": "user",
        "content": "Find recent news about AI developments"
    }],
)
```

---

## PDF to Markdown Extraction

Convert PDF documents to markdown text. Supports both synchronous and streaming modes.

### Non-Streaming Extraction

Returns all pages at once:

```python
import requests

response = requests.post(
    "https://api.llmgateway.ciridae.app/extraction/pdf_to_markdown",
    json={
        "document_url": "https://example.com/document.pdf",
        "options": {
            "model": "ocr",
            "custom_prompt": None,  # Optional: override extraction prompt
        }
    },
    headers={"Authorization": "Bearer YOUR_API_KEY"},
)

data = response.json()
for i, page_content in enumerate(data["result"]):
    print(f"--- Page {i + 1} ---")
    print(page_content)
```

### Streaming Extraction

Stream results in batches as they complete (recommended for large documents):

```python
import requests
import json

response = requests.post(
    "https://api.llmgateway.ciridae.app/extraction/pdf_to_markdown/stream",
    json={
        "document_url": "https://example.com/large-document.pdf",
        "options": {
            "stream_batch_size": 5,  # Pages per batch (default: 8)
        }
    },
    headers={"Authorization": "Bearer YOUR_API_KEY"},
    stream=True,
)

for line in response.iter_lines():
    if line:
        line = line.decode("utf-8")
        if line.startswith("data: "):
            data = line[6:]
            if data == "[DONE]":
                print("Stream complete")
                break
            try:
                batch = json.loads(data)
                if "error" in batch:
                    print(f"Error: {batch['error']}")
                else:
                    print(f"Batch {batch['batch_index']}: {len(batch['pages'])} pages")
                    # Process batch['pages'] as they arrive
            except json.JSONDecodeError:
                pass
```

### Base64 Input

Upload documents directly as base64:

```python
import base64
import requests

with open("document.pdf", "rb") as f:
    pdf_base64 = base64.b64encode(f.read()).decode("utf-8")

response = requests.post(
    "https://api.llmgateway.ciridae.app/extraction/pdf_to_markdown",
    json={
        "document_base64": f"data:application/pdf;base64,{pdf_base64}",
        # or just: "document_base64": pdf_base64
    },
    headers={"Authorization": "Bearer YOUR_API_KEY"},
)
```

### Request Options

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `document_url` | string | - | URL to fetch the document from |
| `document_base64` | string | - | Base64-encoded document (provide one of url or base64) |
| `options.model` | string | `"ocr"` | Model for extraction |
| `options.custom_prompt` | string | `null` | Custom extraction prompt |
| `options.stream_batch_size` | int | `8` | Pages per streaming batch |

### Streaming Response Format

```json
{"batch_index": 0, "pages": ["Page 1 content...", "Page 2 content..."], "total_pages": 50}
{"batch_index": 1, "pages": ["Page 3 content...", "Page 4 content..."], "total_pages": 50}
...
[DONE]
```

**Ordering guarantees:**
- Batches are delivered in strict sequential order
- Each batch contains pages in order
- A batch is only sent when all its pages complete

---

## Error Handling

### HTTP Status Codes

| Code | Meaning |
|------|---------|
| `400` | Invalid request (bad parameters, missing fields) |
| `401` | Invalid or missing API key |
| `429` | Rate limited |
| `500` | Server error |

### Best Practices

```python
from openai import OpenAI, APIError, RateLimitError

client = OpenAI(
    api_key="your-api-key",
    base_url="https://api.llmgateway.ciridae.app",
)

try:
    response = client.chat.completions.create(
        model="fast-production",
        messages=[{"role": "user", "content": "Hello"}],
    )
except RateLimitError:
    # Use exponential backoff or switch models
    pass
except APIError as e:
    print(f"API error: {e}")
```

---

## Summary

| Feature | Chat Completions | Responses API | Extraction |
|---------|-----------------|---------------|------------|
| Endpoint | `/chat/completions` | `/responses` | `/extraction/pdf_to_markdown` |
| Streaming | Yes | Yes | Yes (separate endpoint) |
| Structured Output | Yes | Yes | N/A |
| Image Input | Yes | Yes | N/A |
| Hosted Tools | No | Yes | N/A |
| Tool/Function Calling | Yes | Yes | N/A |
| Reasoning Control | Yes | Yes | N/A |

**Recommended approach:**
- Use **model routers** (`fast-production`, `strong-production`) for automatic failover
- Use **Responses API** when you need hosted tools
- Use **Chat Completions** for standard chat and tool calling
- Use **streaming extraction** for documents over 10 pages

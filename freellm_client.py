"""
FreeLLMAPI Client for Sarkari Job Alert App.
Connects automatically to the local FreeLLMAPI Desktop gateway (http://127.0.0.1:31415).
Provides methods to query available models and run AI completions.
"""

import os
import json
import urllib.request
import urllib.error

DEFAULT_BASE_URL = os.getenv("FREELLMAPI_BASE_URL", "http://127.0.0.1:31415/v1")
DEFAULT_API_KEY = os.getenv("FREELLMAPI_API_KEY", "freellmapi-b034f7466b480649850d74c3e6df9652e5ed995c69ffed9d")


class FreeLLMClient:
    def __init__(self, base_url: str = DEFAULT_BASE_URL, api_key: str = DEFAULT_API_KEY):
        self.base_url = base_url.rstrip("/")
        self.api_key = api_key

    def _headers(self):
        return {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
            "User-Agent": "SarkariJobAlertApp/1.0"
        }

    def get_available_models(self, ready_only: bool = True):
        """
        Fetch all models exposed by FreeLLMAPI.
        If ready_only is True, returns only models that can currently execute requests.
        """
        url = f"{self.base_url}/models"
        req = urllib.request.Request(url, headers=self._headers(), method="GET")
        
        try:
            with urllib.request.urlopen(req, timeout=10) as resp:
                data = json.loads(resp.read().decode("utf-8"))
                models = data.get("data", [])
                if ready_only:
                    return [
                        m for m in models 
                        if m.get("available") is True or m.get("execution_status") == "ready"
                    ]
                return models
        except Exception as e:
            raise RuntimeError(f"Failed to fetch models from FreeLLMAPI ({url}): {e}")

    def chat_completion(self, messages, model: str = "auto", temperature: float = 0.7, max_tokens: int = 1000):
        """
        Send a chat completion request to FreeLLMAPI.
        'auto' will let FreeLLMAPI smart router pick the best available free model.
        """
        url = f"{self.base_url}/chat/completions"
        payload = {
            "model": model,
            "messages": messages,
            "temperature": temperature,
            "max_tokens": max_tokens
        }
        data = json.dumps(payload).encode("utf-8")
        req = urllib.request.Request(url, data=data, headers=self._headers(), method="POST")

        try:
            with urllib.request.urlopen(req, timeout=30) as resp:
                result = json.loads(resp.read().decode("utf-8"))
                choice = result.get("choices", [{}])[0]
                message = choice.get("message", {})
                return {
                    "content": message.get("content", ""),
                    "model_used": result.get("model", model),
                    "usage": result.get("usage", {})
                }
        except urllib.error.HTTPError as e:
            err_body = e.read().decode("utf-8") if hasattr(e, "read") else str(e)
            raise RuntimeError(f"FreeLLMAPI HTTP {e.code} Error: {err_body}")
        except Exception as e:
            raise RuntimeError(f"FreeLLMAPI Connection Error: {e}")

    def summarize_job_post(self, title: str, eligibility: str, last_date: str = "", model: str = "auto"):
        """Generate a concise Hindi-English summary of a government job post."""
        prompt = (
            f"Job Title: {title}\n"
            f"Eligibility: {eligibility}\n"
            f"Last Date: {last_date}\n\n"
            "Summarize this job in 3 bullet points (Hinglish/English): Key Role, Eligibility criteria, and why candidates should apply."
        )
        messages = [
            {"role": "system", "content": "You are an expert Sarkari Job guidance counselor in India."},
            {"role": "user", "content": prompt}
        ]
        return self.chat_completion(messages, model=model)


if __name__ == "__main__":
    print("[*] Testing FreeLLMClient connection...")
    client = FreeLLMClient()
    
    try:
        ready_models = client.get_available_models(ready_only=True)
        print(f"[+] Connected! Ready models count: {len(ready_models)}")
        print(f"[+] Sample ready models: {[m['id'] for m in ready_models[:5]]}")
        
        print("\n[*] Sending test prompt to 'auto' model...")
        response = client.chat_completion([
            {"role": "user", "content": "Hello! Confirm you are working in one sentence."}
        ])
        print(f"[+] FreeLLMAPI Response:\n{response['content']}")
        print(f"[+] Backend Model Routed: {response['model_used']}")
        
    except Exception as ex:
        print(f"[-] Error: {ex}")

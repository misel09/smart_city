import os
import json
import concurrent.futures
from typing import Optional, List, Dict
from google import genai
from google.genai import types
from gradio_client import Client, handle_file
from PIL import Image
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Configure Gemini
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")

class AIUtils:
    def __init__(self):
        self.client = None
        if GEMINI_API_KEY:
            self.client = genai.Client(api_key=GEMINI_API_KEY)
        
        self.hf_client = None
        hf_token = os.getenv("HF_TOKEN")
        try:
            self.hf_client = Client("23it085/urban-issues-classifier", token=hf_token)
        except Exception as e:
            # Silent failure for init; we'll retry or fallback later
            print(f"HF Init error: {e}")
            pass
        
        self.categories = [
            "Damaged concrete structures",
            "Damaged Electrical Poles",
            "Damaged Road Signs",
            "Dead Animals / Pollution",
            "Garbage",
            "Fallen Trees",
            "Graffiti",
            "Illegal Parking",
            "Potholes and Road Cracks"
        ]

    def classify_issue(self, image_path: str) -> str:
        """
        Classifies the urban issue using Hugging Face.
        Optimized to assume the image is already sized appropriately.
        """
        try:
            # Check if this is a temp thumbnail we should delete after use
            is_temp = "_hf_thumb.jpg" in image_path
            
            if not self.hf_client:
                 hf_token = os.getenv("HF_TOKEN")
                 self.hf_client = Client("23it085/urban-issues-classifier", token=hf_token)
            
            # Use a thread pool to enforce a timeout on the HF call
            with concurrent.futures.ThreadPoolExecutor(max_workers=1) as executor:
                future = executor.submit(
                    self.hf_client.predict, 
                    handle_file(image_path), 
                    api_name="/predict"
                )
                try:
                    result = future.result(timeout=30)  # Increased to 30s but we optimize image
                except concurrent.futures.TimeoutError:
                    print("Hugging Face still took too long (30s), falling back to Gemini...")
                    return "Unclassified"
                finally:
                    pass # Deletion handled by caller (analyze_image)
            
            if isinstance(result, dict) and 'label' in result:
                return result['label']
            return str(result)
        except Exception as e:
            print(f"HF Classification error: {e}")
            return "Unclassified"

    def generate_description(self, image_path: str, issue_type: Optional[str] = None) -> Dict[str, str]:
        """
        Generates a structured description and priority of the issue using Gemini.
        """
        if not self.client:
            return {
                "description": f"A {issue_type or 'urban issue'} has been reported.",
                "priority": "Normal"
            }

        try:
            img = Image.open(image_path)
            
            prompt = (
                "You are a professional QA engineer.\n\n"
                "Input:\n"
                f"- Suggested Issue Type: {issue_type or 'Auto-Detect'}\n"
                "- Image: provided\n"
                f"- Allowed Categories: {', '.join(self.categories)}\n\n"
                "Task:\n"
                "1. Analyze the image.\n"
                "2. Confirm or correct the Issue Type. If the Suggested Issue Type is 'Unclassified' or 'Auto-Detect', "
                "select the most appropriate category from the Allowed Categories list.\n"
                "3. Write a clear and concise description of the issue (max 2 sentences).\n"
                "4. Assign a priority level: Normal, Medium, High, or Urgent.\n\n"
                "Priority Guidelines:\n"
                "- Normal → Minor issue, does not affect functionality.\n"
                "- Medium → Noticeable issue, affects usability but has a workaround.\n"
                "- High → Major issue, significantly impacts user experience or core functionality.\n"
                "- Urgent → Critical issue, blocks usage, causes crash, or breaks key features.\n\n"
                "Return the result ONLY as a JSON object with keys 'category', 'description', and 'priority'."
            )
            
            # Fallback chain for models - prioritize Flash for speed
            models_to_try = ["gemini-2.0-flash", "gemini-flash-latest", "gemini-2.5-pro"]
            
            # Use original image or already optimized one
            optimized_img = img
            
            for model_name in models_to_try:
                try:
                    response = self.client.models.generate_content(
                        model=model_name,
                        contents=[prompt, optimized_img],
                        config=types.GenerateContentConfig(
                            response_mime_type="application/json",
                        )
                    )
                    if response and response.text:
                        result = json.loads(response.text)
                        return {
                            "category": result.get("category", issue_type),
                            "description": result.get("description", ""),
                            "priority": result.get("priority", "Normal")
                        }
                except Exception as e:
                    print(f"Gemini {model_name} failed: {e}")
                    continue
            
            return {
                "description": f"Automated report for {issue_type or 'issue'}.",
                "priority": "Normal"
            }
                
        except Exception as e:
            print(f"Error in Gemini analysis: {e}")
            return {
                "description": f"Automated report for {issue_type or 'issue'}.",
                "priority": "Normal"
            }

    def analyze_image(self, image_path: str) -> Dict[str, str]:
        """
        Analyzes an image: runs Hugging Face classification and Gemini description in PARALLEL.
        """
        print(f"--- [PARALLEL PIPELINE] Starting AI analysis for: {image_path} ---")
        
        # 1. Pre-process images for both services in parallel to save time
        hf_img_path = f"{image_path}_hf_thumb.jpg"
        gemini_img_path = f"{image_path}_gem_opt.jpg"
        
        try:
            with Image.open(image_path) as img:
                # Small thumbnail for HF (they usually only need 224x224)
                img_hf = img.copy()
                img_hf.thumbnail((224, 224), Image.Resampling.LANCZOS)
                img_hf.convert('RGB').save(hf_img_path, "JPEG", quality=70)
                
                # Optimized size for Gemini (512px is plenty for 1.5/2.0 Flash)
                img_gem = img.copy()
                img_gem.thumbnail((512, 512), Image.Resampling.LANCZOS)
                img_gem.convert('RGB').save(gemini_img_path, "JPEG", quality=80)
        except Exception as e:
            print(f"Warning: Parallel image optimization failed: {e}")
            hf_img_path = image_path
            gemini_img_path = image_path

        # 2. Run both services concurrently
        with concurrent.futures.ThreadPoolExecutor(max_workers=2) as executor:
            # Future for Hugging Face
            hf_future = executor.submit(self.classify_issue, hf_img_path)
            # Future for Gemini
            gemini_future = executor.submit(self.generate_description, gemini_img_path)
            
            # Wait for results with a total timeout
            try:
                category = hf_future.result(timeout=35)
                print(f"Hugging Face Result: {category}")
            except Exception as e:
                print(f"Hugging Face parallel call failed: {e}")
                category = "Unclassified"
                
            try:
                analysis = gemini_future.result(timeout=35)
                desc = analysis.get('description') or ""
                print(f"Gemini Result: {desc[:50]}...")
            except Exception as e:
                print(f"Gemini parallel call failed: {e}")
                analysis = {"description": "Analysis failed", "priority": "Normal"}

        # 3. Merge results
        # If HF failed or returned Unclassified, use Gemini's category if it extracted one
        if category == "Unclassified" or category == "Auto-Detect":
            category = analysis.get("category", category)
            
        description = analysis.get("description", "")
        priority = analysis.get("priority", "Normal")
        
        print(f"Final Resolved Category: {category}")
        print(f"Final Resolved Priority: {priority}")
        print("--- AI analysis complete ---")
        
        # Clean up temp files
        for p in [hf_img_path, gemini_img_path]:
            if p != image_path and os.path.exists(p):
                try:
                    os.remove(p)
                except:
                    pass
            
        return {
            "category": category,
            "description": description,
            "priority": priority
        }

ai_utils = AIUtils()

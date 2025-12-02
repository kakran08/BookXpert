from fastapi import FastAPI, Depends, HTTPException, Header
import sqlite3
from typing import Optional
import torch

app = FastAPI(title="API Key Login Example")

DB_PATH = "auth.db"

def get_db():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    conn = get_db()
    cur = conn.cursor()

    cur.execute("""
        CREATE TABLE IF NOT EXISTS api_keys (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE NOT NULL,
            password TEXT NOT NULL,
            api_key TEXT NOT NULL
        );
    """)

    cur.execute("""
        INSERT OR IGNORE INTO api_keys (username, password, api_key)
        VALUES ('admin', 'admin123', 'mysecretkey123');
    """)

    conn.commit()
    conn.close()

init_db()

from transformers import AutoTokenizer, AutoModelForCausalLM
from peft import PeftModel
import torch

MODEL_PATH = "qlora_lora_tinyllama/content/qlora_lora_tinyllama"

tokenizer = AutoTokenizer.from_pretrained(MODEL_PATH, use_fast=True, legacy=False)

model = AutoModelForCausalLM.from_pretrained(
    MODEL_PATH,
    dtype=torch.float16,
    device_map="auto"
)

model = PeftModel.from_pretrained(model, MODEL_PATH)
model.eval()


def verify_api_key(x_api_key: Optional[str] = Header(None)):
    if x_api_key is None:
        raise HTTPException(status_code=401, detail="Missing API key")

    conn = get_db()
    cur = conn.cursor()
    cur.execute("SELECT * FROM api_keys WHERE api_key = ?", (x_api_key,))
    user = cur.fetchone()

    if not user:
        raise HTTPException(status_code=401, detail="Invalid API key")

    return user["username"]

# @app.get("/recipe")
# def home(username: str = Depends(verify_api_key)):
#     return {"message": "Welcome!", "user": username}

@app.post("/login")
def login(username: str, password: str):
    conn = get_db()
    cur = conn.cursor()
    cur.execute(
        "SELECT api_key FROM api_keys WHERE username = ? AND password = ?",
        (username, password)
    )
    row = cur.fetchone()

    if not row:
        raise HTTPException(status_code=401, detail="Invalid username or password")

    return {"api_key": row["api_key"]}


@app.get("/recipe")
def get_recipe(
    ingredients: str,
    username: str = Depends(verify_api_key)
):
    """
    Example: /recipe?ingredients=Egg,Onions
    """

    # Build the structured cooking-assistant prompt
    prompt = (
        "<<system>> You are a skilled cooking assistant.\n"
        f"<<user>> Suggest a clean, well-formatted recipe using these ingredients: {ingredients}\n"
        "<<assistant>>"
    )

    # Tokenize
    inputs = tokenizer(prompt, return_tensors="pt").to(model.device)

    # Generate
    with torch.no_grad():
        output_ids = model.generate(
            **inputs,
            max_new_tokens=350,
            do_sample=True,
            temperature=0.7,
            top_p=0.9,
            eos_token_id=tokenizer.eos_token_id,
        )

    recipe = tokenizer.decode(output_ids[0], skip_special_tokens=True)

    return {
        "message": "Here is your recipe!",
        "user": username,
        "ingredients": ingredients,
        "recipe": recipe,
    }

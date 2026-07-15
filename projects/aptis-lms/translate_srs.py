import os
import re
import time
from pathlib import Path
from deep_translator import GoogleTranslator

def translate_chunk(text, translator):
    if not text or not text.strip():
        return text
    try:
        return translator.translate(text)
    except Exception as e:
        print(f"      [!] Error translating chunk: {e}")
        time.sleep(2)
        try:
            return translator.translate(text)
        except:
            return text

def translate_markdown_file(src_path, dest_path, translator):
    print(f"    - Translating {src_path.name}...")
    content = src_path.read_text(encoding="utf-8")
    
    # 1. Extract code blocks to preserve them untranslated
    # Matches ```lang ... ``` blocks
    code_pattern = r'(```.*?```)'
    code_blocks = re.findall(code_pattern, content, re.DOTALL)
    
    placeholder_text = content
    placeholders = []
    for idx, block in enumerate(code_blocks):
        placeholder = f"__CODE_BLOCK_PLACEHOLDER_{idx}__"
        placeholders.append((placeholder, block))
        placeholder_text = placeholder_text.replace(block, f"\n\n{placeholder}\n\n")
        
    # 2. Split into chunks of up to 4000 characters along double newlines (paragraphs)
    paragraphs = placeholder_text.split("\n\n")
    chunks = []
    current_chunk = []
    current_length = 0
    
    for para in paragraphs:
        if current_length + len(para) + 2 > 4000:
            if current_chunk:
                chunks.append("\n\n".join(current_chunk))
            current_chunk = [para]
            current_length = len(para)
        else:
            current_chunk.append(para)
            current_length += len(para) + 2
            
    if current_chunk:
        chunks.append("\n\n".join(current_chunk))
        
    # 3. Translate each chunk
    translated_chunks = []
    for i, chunk in enumerate(chunks):
        # Skip translation if chunk is just a single code block placeholder
        chunk_strip = chunk.strip()
        if re.match(r'^__CODE_BLOCK_PLACEHOLDER_\d+__$', chunk_strip):
            translated_chunks.append(chunk)
            continue
            
        print(f"      * Translating chunk {i+1}/{len(chunks)} ({len(chunk)} chars)...")
        translated_chunk = translate_chunk(chunk, translator)
        translated_chunks.append(translated_chunk)
        # Sleep slightly to prevent rate limits
        time.sleep(0.5)
        
    translated_content = "\n\n".join(translated_chunks)
    
    # 4. Restore the original code blocks
    for placeholder, original_block in placeholders:
        # Google Translate might alter spacing around placeholder, clean it up
        # Try both direct replace and regex replace
        translated_content = translated_content.replace(placeholder, original_block)
        # Fallback regex search for mutated case (e.g. spaces added)
        clean_placeholder = placeholder.replace("_", " ") # just in case
        translated_content = re.sub(r'__\s*CODE\s*BLOCK\s*PLACEHOLDER\s*_\s*' + str(placeholders.index((placeholder, original_block))) + r'\s*__', original_block, translated_content, flags=re.IGNORECASE)
        
    dest_path.write_text(translated_content, encoding="utf-8")
    print(f"    [+] Finished translating {src_path.name}")

def main():
    src_dir = Path("srs")
    dest_dir = Path("srs-vi")
    dest_dir.mkdir(exist_ok=True)
    
    translator = GoogleTranslator(source='en', target='vi')
    
    md_files = sorted(list(src_dir.glob("*.md")))
    if not md_files:
        print("[!] No files found in 'srs' directory.")
        return
        
    print(f"[*] Starting optimized translation of {len(md_files)} files...")
    start_time = time.time()
    
    for f in md_files:
        dest_file = dest_dir / f.name
        translate_markdown_file(f, dest_file, translator)
        time.sleep(1)
        
    duration = time.time() - start_time
    print(f"[+] All files translated successfully in {duration:.1f}s!")

if __name__ == "__main__":
    main()

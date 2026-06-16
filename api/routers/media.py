"""Media upload router — stores task attachments in UploadThing.

Requires environment variables:
- UPLOADTHING_TOKEN
"""
from fastapi import APIRouter, UploadFile, File, HTTPException
import os
import requests

router = APIRouter(prefix="/upload", tags=["media"])

UPLOADTHING_TOKEN = os.getenv("UPLOADTHING_TOKEN", "")

MAX_BYTES   = 10 * 1024 * 1024   # 10 MB
ALLOWED     = {"image/jpeg", "image/png", "image/gif", "image/webp", "image/svg+xml"}

@router.post("/image")
async def upload_image(file: UploadFile = File(...)):
    """Accept an image file, upload to UploadThing, return { url, name }."""
    if not UPLOADTHING_TOKEN:
        raise HTTPException(
            status_code=503,
            detail="Media storage not configured — set UPLOADTHING_TOKEN."
        )

    content_type = (file.content_type or "").split(";")[0].strip().lower()
    if content_type not in ALLOWED:
        raise HTTPException(
            status_code=415,
            detail=f"Unsupported file type '{content_type}'. Accepted: JPEG, PNG, GIF, WebP, SVG."
        )

    data = await file.read()
    if len(data) > MAX_BYTES:
        raise HTTPException(status_code=413, detail=f"File too large (max {MAX_BYTES // 1024 // 1024} MB).")

    # Upload to UploadThing via their REST API
    try:
        response = requests.post(
            "https://uploadthing.com/api/uploadFiles",
            headers={"x-uploadthing-api-key": UPLOADTHING_TOKEN},
            files={"files": (file.filename or "upload.bin", data, content_type)}
        )
        response.raise_for_status()
        result = response.json()
        
        # UploadThing returns a list of objects like [{"url": "...", "name": "..."}]
        if isinstance(result, list) and len(result) > 0:
            file_info = result[0]
            # Replace utfs.io with ufs.sh which is the standard now, although both work.
            file_url = file_info.get("url") or file_info.get("fileUrl")
            if not file_url:
                # Some older api versions return fileUrl
                raise Exception("No URL returned from UploadThing")
            
            return {"url": file_url, "name": file_info.get("name", file.filename)}
        else:
            raise Exception("Invalid response from UploadThing API")

    except requests.exceptions.RequestException as e:
        raise HTTPException(status_code=500, detail=f"Upload failed (Network): {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Upload failed: {str(e)}")

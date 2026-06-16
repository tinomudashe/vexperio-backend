"""Media upload router — stores task attachments in Cloudflare R2 / S3.

Requires environment variables:
- S3_BUCKET_NAME
- S3_ENDPOINT_URL
- S3_ACCESS_KEY
- S3_SECRET_KEY
"""
from fastapi import APIRouter, UploadFile, File, HTTPException
import os
import uuid
import boto3
from botocore.exceptions import ClientError

router = APIRouter(prefix="/upload", tags=["media"])

S3_BUCKET = os.getenv("S3_BUCKET_NAME", "")
S3_ENDPOINT = os.getenv("S3_ENDPOINT_URL", "")
S3_ACCESS = os.getenv("S3_ACCESS_KEY", "")
S3_SECRET = os.getenv("S3_SECRET_KEY", "")
S3_PUBLIC_URL = os.getenv("S3_PUBLIC_URL", "")

MAX_BYTES   = 10 * 1024 * 1024   # 10 MB
ALLOWED     = {"image/jpeg", "image/png", "image/gif", "image/webp", "image/svg+xml"}
EXT_MAP     = {
    "image/jpeg":    "jpg",
    "image/png":     "png",
    "image/gif":     "gif",
    "image/webp":    "webp",
    "image/svg+xml": "svg",
}

@router.post("/image")
async def upload_image(file: UploadFile = File(...)):
    """Accept an image file, upload to S3/R2, return { url, name }."""
    if not S3_BUCKET or not S3_ENDPOINT:
        raise HTTPException(
            status_code=503,
            detail="Media storage not configured — set S3_BUCKET_NAME and S3_ENDPOINT_URL."
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

    ext       = EXT_MAP.get(content_type, "bin")
    blob_name = f"task-attachments/{uuid.uuid4().hex}.{ext}"

    s3_client = boto3.client(
        "s3",
        endpoint_url=S3_ENDPOINT,
        aws_access_key_id=S3_ACCESS,
        aws_secret_access_key=S3_SECRET,
        region_name="auto"
    )

    try:
        s3_client.put_object(
            Bucket=S3_BUCKET,
            Key=blob_name,
            Body=data,
            ContentType=content_type
        )
        if S3_PUBLIC_URL:
            public_url = f"{S3_PUBLIC_URL.rstrip('/')}/{blob_name}"
        else:
            public_url = f"{S3_ENDPOINT.rstrip('/')}/{S3_BUCKET}/{blob_name}"

        return {"url": public_url, "name": file.filename or blob_name}
    except ClientError as e:
        raise HTTPException(status_code=500, detail=f"Upload failed: {e}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Upload failed: {e}")

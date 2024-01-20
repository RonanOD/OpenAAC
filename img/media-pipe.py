# https://developers.google.com/mediapipe/solutions/vision/image_generator
# Collab Notebook: https://colab.research.google.com/github/GoogleCloudPlatform/vertex-ai-samples/blob/main/notebooks/community/model_garden/model_garden_mediapipe_image_generation.ipynb
import os
from dotenv import load_dotenv
import json
from datetime import datetime
from google.cloud import aiplatform

load_dotenv()

print(f"Training images for {os.getenv('PROJECT_ID')}")

REGION = "us-central1"  # @param {type: "string"}
REGION_PREFIX = REGION.split("-")[0]
assert REGION_PREFIX in (
    "us",
    "europe",
    "asia",
), f'{REGION} is not supported. It must be prefixed by "us", "asia", or "europe".'

now = datetime.now().strftime("%Y%m%d-%H%M%S")

STAGING_BUCKET = os.path.join(os.getenv("BUCKET_URI"), "temp/%s" % now)

MODEL_EXPORT_PATH = os.path.join(STAGING_BUCKET, "model")

IMAGE_EXPORT_PATH = os.path.join(STAGING_BUCKET, "image")

aiplatform.init(project=os.getenv("PROJECT_ID"), location=os.getenv("REGION"), staging_bucket=STAGING_BUCKET)

TRAINING_JOB_DISPLAY_NAME = "mediapipe_stable_diffusion_%s" % now
TRAINING_CONTAINER = f"{REGION_PREFIX}-docker.pkg.dev/vertex-ai-restricted/vertex-vision-model-garden-dockers/mediapipe-stable-diffusion-train"
TRAINING_MACHINE_TYPE = "a2-highgpu-1g"
TRAINING_ACCELERATOR_TYPE = "NVIDIA_TESLA_A100"
TRAINING_ACCELERATOR_COUNT = 1

PREDICTION_CONTAINER_URI = f"{REGION_PREFIX}-docker.pkg.dev/vertex-ai/vertex-vision-model-garden-dockers/pytorch-peft-serve"
PREDICTION_PORT = 7080
PREDICTION_ACCELERATOR_TYPE = "NVIDIA_TESLA_V100"
PREDICTION_MACHINE_TYPE = "n1-standard-8"
UPLOAD_MODEL_NAME = "mediapipe_stable_diffusion_model_%s" % now

unet_url = "https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/unet/diffusion_pytorch_model.bin"  # @param {type:"string"}
vae_url = "https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/vae/diffusion_pytorch_model.bin"  # @param {type:"string"}
text_encoder_url = "https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/text_encoder/pytorch_model.bin"  # @param {type:"string"}


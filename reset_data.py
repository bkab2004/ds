import os
import shutil
from pathlib import Path
# pyrefly: ignore [missing-import]
from pymongo import MongoClient

def reset_all_data():
    # 1. Clear MongoDB collections
    client = MongoClient("mongodb://localhost:27017")
    db = client["distriflow"]
    db.files.delete_many({})
    db.tasks.delete_many({})
    db.processing_history.delete_many({})
    db.benchmarks.delete_many({})
    db.workers.delete_one({"worker_id": "worker-4"})
    db.workers.update_many(
        {"worker_id": {"$in": ["worker-1", "worker-2", "worker-3"]}},
        {"$set": {
            "current_tasks": 0,
            "completed_tasks": 0,
            "failed_tasks": 0,
            "status": "ONLINE",
            "deactivated_manually": False
        }}
    )
    print("MongoDB files, tasks, history, benchmarks cleared and worker-4 removed.")

    # 2. Clear storage files
    base_storage = Path(__file__).parent / "storage"
    for folder in ["uploads", "processed", "thumbnails"]:
        p = base_storage / folder
        if p.exists():
            for item in p.iterdir():
                if item.name != ".gitkeep":
                    if item.is_dir():
                        shutil.rmtree(item)
                    else:
                        item.unlink()
            print(f"Cleared storage/{folder}")

if __name__ == "__main__":
    reset_all_data()
    print("All system data has been completely reset!")

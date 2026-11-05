# DistriFlow – Distributed File Processing & Storage System

> **B.Tech Computer Engineering – Distributed Systems FA/Mini Project**

A **genuine distributed system** that processes image files across multiple independent worker services, coordinated by a central Coordinator using gRPC, with real-time monitoring via a professional React dashboard.

---

## 📸 Screenshots

> *(Add screenshots after running the system)*
> - Dashboard with worker cards and charts
> - Upload page
> - Tasks page with status filters
> - Worker failure demonstration

---

## 1. Project Overview

DistriFlow demonstrates core distributed systems concepts by actually implementing them:

| Concept | Implementation |
|---------|---------------|
| Distributed Computing | 3+ independent worker processes in separate Docker containers / processes |
| Message Passing | gRPC (Protocol Buffers) for Coordinator ↔ Worker communication |
| Task Distribution | Least-loaded worker scheduling algorithm |
| Fault Detection | Heartbeat-based failure detection (30s timeout) & Admin Toggle |
| Fault Recovery | Automatic task reassignment when a worker fails |
| Elastic Scaling | Dynamic worker spawning (`+ Add Worker`) on the fly |
| Performance Benchmarking | Live Sequential vs. Distributed speedup & Amdahl efficiency test |
| Parallel Image Filters | Resize, Grayscale, Thumbnail, Blur, Sepia, Edge Detect, Invert, Metadata |
| Persistent Storage | MongoDB for all state (tasks, workers, files, history, benchmarks) |
| Containerization | Docker + Docker Compose for reproducible deployment |
| Real-time Monitoring | WebSocket-based live dashboard |

---

## 2. Problem Statement

Modern file processing systems need to handle thousands of files efficiently. A single server can become a bottleneck. How do we:
- Process files faster using multiple machines?
- Handle server failures without losing work?
- Monitor the system in real-time?
- Scale up by adding more workers without rewriting code?

**DistriFlow solves these problems using distributed systems principles.**

---

## 3. Architecture

```
┌─────────────────────────────────────────────────────┐
│                React Dashboard (Port 3000)           │
│         Upload │ Monitor │ Files │ Workers │ Tasks   │
└──────────────────────┬──────────────────────────────┘
                       │ REST / WebSocket
┌──────────────────────▼──────────────────────────────┐
│              FastAPI REST API (Port 8000)            │
│   /upload  /files  /tasks  /workers  /dashboard/stats│
└──────────────────────┬──────────────────────────────┘
                       │ Internal Python calls
┌──────────────────────▼──────────────────────────────┐
│              Coordinator (gRPC Port 50050)           │
│  ┌────────────────┐  ┌─────────────────────────┐    │
│  │ Task Scheduler │  │     Health Monitor      │    │
│  │ (Least-loaded) │  │ (Heartbeat timeout det) │    │
│  └────────────────┘  └─────────────────────────┘    │
└──────┬───────────────────┬───────────────┬──────────┘
       │ gRPC              │ gRPC          │ gRPC
┌──────▼──────┐  ┌─────────▼──────┐ ┌─────▼────────┐
│  Worker 1   │  │   Worker 2     │ │   Worker 3   │
│ Port: 50051 │  │  Port: 50052   │ │ Port: 50053  │
│ Pillow      │  │  Pillow        │ │ Pillow       │
└──────┬──────┘  └─────────┬──────┘ └─────┬────────┘
       └─────────────┬──────┘──────────────┘
                     │
              ┌──────▼──────┐
              │   MongoDB   │
              │  Port 27017 │
              └─────────────┘
```

---

## 4. Technologies Used

| Layer | Technology | Reason |
|-------|-----------|--------|
| Frontend | React + Vite | Modern reactive UI |
| Charts | Recharts | Beautiful data visualization |
| REST API | FastAPI (Python) | Fast async API with auto docs |
| gRPC | grpcio + grpc_tools | Efficient binary RPC between services |
| Proto | Protocol Buffers | Language-neutral message serialization |
| Image Processing | Pillow | Industry-standard Python image library |
| Database | MongoDB | Document store; flexible schema for tasks/workers |
| Containerization | Docker + Compose | Isolated, reproducible services |
| Web Server | Nginx | Serves React build + proxies API |

---

## 5. Components

### 🧠 Coordinator (`coordinator/`)
- **gRPC Server** on port 50050
- Accepts worker registrations and heartbeats
- Runs **Task Scheduler** (background thread) that assigns PENDING tasks
- Runs **Health Monitor** (background thread) that detects worker failures
- Handles task result reporting and retry logic

### ⚙️ Worker (`worker/`)
- Each worker runs as an independent Docker container
- On startup: registers with Coordinator via gRPC
- Sends heartbeats every 10 seconds
- Processes images using Pillow when assigned tasks
- Reports results back to Coordinator

### 🌐 FastAPI (`api/`)
- REST endpoint for React dashboard
- File upload handler (saves to shared storage volume)
- Creates task records in MongoDB
- WebSocket endpoint for real-time push updates

### 💻 React Dashboard (`frontend/`)
- Dashboard: stats, worker cards, charts
- Upload: drag-and-drop with operation selection
- Files: management table with download
- Tasks: filterable task monitor
- Workers: detailed worker monitoring

---

## 6. Communication Mechanism

### REST (React → FastAPI)
Used for file upload and reading data.
```
POST /upload       – upload files
GET  /files        – list files
GET  /tasks        – list tasks
GET  /workers      – list workers
GET  /dashboard/stats – aggregated metrics
```

### WebSocket (React ↔ FastAPI)
Real-time push updates every 2 seconds.
```
WS /ws – connect once, receive streaming updates
```

### gRPC (Coordinator ↔ Workers)
Binary, efficient RPC defined in `proto/distributed.proto`.

**Workers → Coordinator:**
```protobuf
RegisterWorker(WorkerInfo) → RegisterResponse
SendHeartbeat(HeartbeatRequest) → HeartbeatResponse
ReportTaskResult(TaskResult) → Empty
```

**Coordinator → Workers:**
```protobuf
ProcessTask(TaskRequest) → Empty
GetStatus(StatusRequest) → WorkerStatusResponse
```

---

## 7. Task Distribution – Least-Loaded Worker Algorithm

```python
# Pseudocode for scheduler.py
def pick_worker():
    workers = db.workers.find(
        status IN ["ONLINE", "BUSY"],
        sort by current_tasks ASC   # ascending = least loaded first
    )
    for w in workers:
        if w.current_tasks < MAX_TASKS_PER_WORKER:
            return w
    return None   # all at capacity
```

**Why least-loaded?**
- Adapts to heterogeneous workers (faster workers get more tasks naturally)
- Prevents any single worker from being overwhelmed
- Better than round-robin when tasks have variable duration

---

## 8. Worker Failure Detection

```
Worker 2 sends heartbeat every 10 seconds.

Health Monitor checks every 10 seconds:
  if (now - worker.last_heartbeat) > 30 seconds:
      worker.status = FAILED
      find all ASSIGNED/PROCESSING tasks for worker-2
      set those tasks to RETRYING
      scheduler will pick them up next cycle
```

**Timeline:**
```
T=0s   Worker 2 last heartbeat
T=30s  Worker 2 stops (docker compose stop worker2)
T=40s  Health Monitor detects timeout (30s threshold)
T=42s  Worker 2 marked FAILED
T=42s  Tasks from Worker 2 → RETRYING status
T=44s  Scheduler assigns tasks to Worker 1 and Worker 3
T=44s  Dashboard shows: Worker 2 🔴 FAILED, Tasks Reassigned
```

---

## 9. Fault Recovery

1. Worker fails → Health Monitor marks FAILED
2. Tasks ASSIGNED/PROCESSING on failed worker → RETRYING
3. retry_count incremented
4. Scheduler picks up RETRYING tasks next cycle
5. Assigns to remaining ONLINE workers
6. Max 3 retries before task marked permanently FAILED

---

## 10. Database Design (MongoDB)

### `workers` collection
```json
{
  "worker_id": "worker-1",
  "hostname": "worker1",
  "port": 50051,
  "grpc_host": "worker1",
  "status": "ONLINE",
  "current_tasks": 2,
  "completed_tasks": 47,
  "failed_tasks": 1,
  "last_heartbeat": "2024-01-01T12:00:00Z",
  "cpu_percent": 35.2,
  "memory_percent": 41.0
}
```

### `tasks` collection
```json
{
  "task_id": "uuid-1",
  "file_id": "uuid-2",
  "filename": "photo.jpg",
  "operation": "thumbnail",
  "status": "COMPLETED",
  "assigned_worker": "worker-1",
  "created_at": "...",
  "started_at": "...",
  "completed_at": "...",
  "retry_count": 0,
  "output_path": "processed/uuid_thumb.jpg",
  "processing_time": 0.342
}
```

### `files` collection
```json
{
  "file_id": "uuid-2",
  "original_name": "photo.jpg",
  "stored_name": "uuid-2.jpg",
  "size": 204800,
  "operation": "thumbnail",
  "status": "COMPLETED",
  "upload_time": "...",
  "output_path": "processed/uuid_thumb.jpg"
}
```

---

## 11. Docker Architecture

Each service is isolated in its own container:

```yaml
mongodb    – data persistence
coordinator – central scheduler + health monitor
worker1    – independent processor (port 50051)
worker2    – independent processor (port 50052)
worker3    – independent processor (port 50053)
api        – REST + WebSocket bridge
frontend   – Nginx serving React
```

All services share:
- `distriflow-net` Docker network (communicate by service name)
- `storage-data` volume (shared file storage)

---

## 12. How to Run

### Prerequisites
- Docker Desktop (Windows/Mac) or Docker Engine (Linux)
- Docker Compose v2

### Steps

```bash
# 1. Clone / navigate to project
cd distriflow

# 2. Start everything
docker compose up --build

# 3. Open the dashboard
open http://localhost:3000

# 4. Check the API docs
open http://localhost:8000/docs
```

### Expected startup order:
1. MongoDB starts and becomes healthy (~10s)
2. Coordinator starts, connects to MongoDB
3. Workers start, register with Coordinator
4. API starts
5. Frontend starts (Nginx serving React build)

---

## 13. How to Test

### Integration Tests (requires running system)

```bash
# Install test dependencies
pip install pytest requests

# Run all tests
python -m pytest tests/ -v

# Run specific test class
python -m pytest tests/test_system.py::TestWorkerRegistration -v
```

### Manual Test

```bash
# Check API health
curl http://localhost:8000/health

# Check workers
curl http://localhost:8000/workers

# Check tasks
curl http://localhost:8000/tasks

# Upload a file
curl -X POST "http://localhost:8000/upload?operation=thumbnail" \
  -F "files=@photo.jpg"
```

---

## 14. How to Demonstrate Worker Failure

**Perfect for college presentations:**

```bash
# Terminal 1 – Watch coordinator logs
docker compose logs -f coordinator

# Terminal 2 – Watch all workers
docker compose logs -f worker1 worker2 worker3

# Terminal 3 – Demo commands

# Step 1: Start system
docker compose up -d

# Step 2: Upload 15 images via dashboard at http://localhost:3000/upload

# Step 3: Watch tasks being distributed across all 3 workers in the Dashboard

# Step 4: KILL Worker 2
docker compose stop worker2

# Step 5: Within 30-40 seconds, coordinator detects failure
# Dashboard shows: Worker 2 🔴 FAILED
# Tasks reassigned to Worker 1 and Worker 3

# Step 6: Restart Worker 2
docker compose start worker2

# Step 7: Worker 2 re-registers
# Dashboard shows: Worker 2 🟢 ONLINE
# New tasks assigned to Worker 2 again
```

---

## 15. Performance Demonstration

The dashboard shows:
- Per-worker task completion counts
- Average processing time
- Processing time trend chart

To compare sequential vs distributed:

| Mode | 30 images | Notes |
|------|----------|-------|
| Sequential (1 worker) | ~X seconds | Only 1 container active |
| Distributed (3 workers) | ~X/3 seconds | Parallel processing |

*(Actual numbers depend on your hardware)*

---

## 16. Project Structure

```
distriflow/
├── proto/
│   └── distributed.proto      # gRPC service definitions
│
├── coordinator/
│   ├── main.py                # gRPC server + coordinator logic
│   ├── scheduler.py           # Task scheduler (least-loaded)
│   ├── health_monitor.py      # Heartbeat failure detection
│   ├── db.py                  # MongoDB connection
│   ├── requirements.txt
│   └── Dockerfile
│
├── worker/
│   ├── main.py                # Worker gRPC server + heartbeat
│   ├── processor.py           # Pillow image processing
│   ├── db.py                  # MongoDB logging
│   ├── requirements.txt
│   └── Dockerfile
│
├── api/
│   ├── main.py                # FastAPI REST + WebSocket
│   ├── requirements.txt
│   └── Dockerfile
│
├── frontend/
│   ├── src/
│   │   ├── pages/             # Dashboard, Upload, Files, Tasks, Workers
│   │   ├── components/        # WorkerCard, StatusBadge, Sidebar
│   │   ├── hooks/             # useWebSocket
│   │   ├── api.js             # API client
│   │   └── index.css          # Design system
│   ├── nginx.conf
│   └── Dockerfile
│
├── tests/
│   └── test_system.py         # Integration tests
│
├── storage/                   # Mounted as Docker volume
│   ├── uploads/
│   ├── processed/
│   └── thumbnails/
│
├── docker-compose.yml
├── .env.example
└── README.md
```

---

## 17. Distributed Systems Concepts Explained

**Q: What is a distributed system?**
Multiple computers working together to achieve a common goal, appearing as a single system to the user.

**Q: Why is this project distributed?**
The Coordinator and each Worker run in separate processes/containers. They communicate over a network. Removing one worker doesn't stop the system.

**Q: What is the Coordinator?**
A central service that knows about all workers, decides which worker gets which task, and monitors worker health.

**Q: What is a Worker?**
An independent service that receives tasks, processes images, and reports results. Each worker operates autonomously.

**Q: Why gRPC?**
- Binary protocol (faster than REST/JSON)
- Strongly typed (protobuf schema)
- Supports streaming
- Works great for internal service communication

**Q: How does heartbeat work?**
Each worker sends a small "I'm alive" message every 10 seconds. If the Coordinator doesn't hear from a worker for 30 seconds, it declares that worker FAILED.

**Q: What happens if the Coordinator fails?**
Workers continue running but can't receive new tasks. Tasks already in MongoDB as PROCESSING remain there. When the Coordinator restarts, it reads state from MongoDB and resumes.

**Q: How does the system scale?**
Add more worker services in docker-compose.yml. Each one registers itself with the Coordinator. No code changes needed in the Coordinator.

---

## 18. Known Limitations

1. **Single Coordinator** – No Coordinator redundancy (SPOF). Production systems would use leader election (e.g., Raft, ZooKeeper).
2. **File size** – Limited to 50MB by default. Large files would need chunked upload.
3. **In-memory connection pool** – Coordinator's gRPC connections to workers are created on-demand. A connection pool would improve performance.
4. **No authentication** – Suitable for demo; production would need JWT/OAuth.

---

## 19. Future Enhancements

- [ ] Coordinator high availability (Raft consensus)
- [ ] Video file processing support
- [ ] Task priority queue
- [ ] Dynamic worker auto-scaling (Kubernetes HPA)
- [ ] S3/MinIO for distributed file storage
- [ ] User authentication and file isolation
- [ ] gRPC streaming for progress updates
- [ ] Prometheus + Grafana metrics

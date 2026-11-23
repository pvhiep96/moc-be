# API Testing Guide

This document provides examples for testing the Project Management API endpoints.

## Base URL
```
http://localhost:3000/api/v1
```

## Authentication
All API endpoints require authentication. Include the admin credentials in the request headers.

## 1. Get All Projects

**Endpoint:** `GET /projects`

**Description:** Get a list of all projects with basic information including thumbnails.

**Request:**
```bash
curl -X GET "http://localhost:3000/api/v1/projects" \
  -H "Content-Type: application/json"
```

**Response:**
```json
[
  {
    "id": 1,
    "name": "Project 1",
    "drive_id": "1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms",
    "show_video": true,
    "video_vertical": {
      "id": 1,
      "url": "https://www.youtube.com/watch?v=example",
      "video_file": null
    },
    "thumbnails": [
      {
        "id": 1,
        "image_url": "https://drive.google.com/uc?id=1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms"
      }
    ],
    "thumbnails_count": 1,
    "cover_image": "https://drive.google.com/uc?id=1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms",
    "hover_image": "https://drive.google.com/uc?id=1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms"
  }
]
```

## 2. Get Project Details

**Endpoint:** `GET /projects/{id}`

**Description:** Get detailed information of a specific project.

**Request:**
```bash
curl -X GET "http://localhost:3000/api/v1/projects/1" \
  -H "Content-Type: application/json"
```

**Response:**
```json
{
  "id": 1,
  "name": "Project 1",
  "drive_id": "1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms",
  "show_video": true,
  "video_vertical": {
    "id": 1,
    "url": "https://www.youtube.com/watch?v=example",
    "video_file": null
  },
  "thumbnails": [
    {
      "id": 1,
      "image_url": "https://drive.google.com/uc?id=1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms"
    }
  ],
  "thumbnails_count": 1,
  "cover_image": "https://drive.google.com/uc?id=1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms",
  "hover_image": "https://drive.google.com/uc?id=1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms"
}
```

## 3. Get Project with All Images

**Endpoint:** `GET /projects/{id}/with_all_images`

**Description:** Get detailed information of a project including all images, videos, and descriptions.

**Request:**
```bash
curl -X GET "http://localhost:3000/api/v1/projects/1/with_all_images" \
  -H "Content-Type: application/json"
```

**Response:**
```json
{
  "id": 1,
  "name": "Project 1",
  "drive_id": "1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms",
  "show_video": true,
  "video_vertical": {
    "id": 1,
    "url": "https://www.youtube.com/watch?v=example",
    "video_file": null
  },
  "thumbnails": [
    {
      "id": 1,
      "image_url": "https://drive.google.com/uc?id=1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms"
    }
  ],
  "thumbnails_count": 1,
  "cover_image": "https://drive.google.com/uc?id=1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms",
  "hover_image": "https://drive.google.com/uc?id=1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms",
  "all_images": [
    {
      "id": 1,
      "image_url": "https://drive.google.com/uc?id=1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms",
      "position": 1
    }
  ],
  "video_urls": [
    {
      "id": 1,
      "url": "https://www.youtube.com/watch?v=example"
    }
  ],
  "descriptions": [
    {
      "id": 1,
      "content": "<p>Project description content</p>",
      "position_display": 1
    }
  ]
}
```

## 4. Manage Thumbnails

### 4.1 Get Project Thumbnails

**Endpoint:** `GET /projects/{id}/thumbnails`

**Description:** Get all thumbnails for a specific project.

**Request:**
```bash
curl -X GET "http://localhost:3000/api/v1/projects/1/thumbnails" \
  -H "Content-Type: application/json"
```

**Response:**
```json
[
  {
    "id": 1,
    "project_id": 1,
    "project_image_id": 1,
    "position": 1,
    "image_url": "https://drive.google.com/uc?id=1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms"
  }
]
```

### 4.2 Add Thumbnail

**Endpoint:** `POST /projects/{id}/thumbnails`

**Description:** Add an image to project thumbnails.

**Request:**
```bash
curl -X POST "http://localhost:3000/api/v1/projects/1/thumbnails" \
  -H "Content-Type: application/json" \
  -d '{
    "image_id": 2
  }'
```

**Response:**
```json
{
  "success": true,
  "message": "Thumbnail added successfully",
  "thumbnail_count": 2
}
```

### 4.3 Remove Thumbnail

**Endpoint:** `DELETE /projects/{id}/thumbnails/{image_id}`

**Description:** Remove an image from project thumbnails.

**Request:**
```bash
curl -X DELETE "http://localhost:3000/api/v1/projects/1/thumbnails/2" \
  -H "Content-Type: application/json"
```

**Response:**
```json
{
  "success": true,
  "message": "Thumbnail removed successfully",
  "thumbnail_count": 1
}
```

### 4.4 Update Thumbnail Order

**Endpoint:** `POST /projects/{id}/thumbnails/update_order`

**Description:** Update the display order of thumbnails.

**Request:**
```bash
curl -X POST "http://localhost:3000/api/v1/projects/1/thumbnails/update_order" \
  -H "Content-Type: application/json" \
  -d '{
    "positions": [
      {"image_id": 2, "position": 1},
      {"image_id": 1, "position": 2}
    ]
  }'
```

**Response:**
```json
{
  "success": true,
  "message": "Thumbnail order updated successfully",
  "positions": [
    {"image_id": 2, "position": 1},
    {"image_id": 1, "position": 2}
  ]
}
```

## Error Responses

### 400 Bad Request
```json
{
  "error": "Invalid parameters"
}
```

### 404 Not Found
```json
{
  "error": "Project not found"
}
```

### 422 Unprocessable Entity
```json
{
  "success": false,
  "error": "Cannot add thumbnail. May have reached the limit of 3 images or image does not exist."
}
```

### 500 Internal Server Error
```json
{
  "success": false,
  "error": "Unknown error occurred"
}
```

## Notes

1. **Thumbnail Limit:** Each project can have a maximum of 3 thumbnails.
2. **Authentication:** All endpoints require valid admin authentication.
3. **Image URLs:** All image URLs are Google Drive direct links.
4. **Position Order:** Positions start from 1 and should be sequential.
5. **Content Types:** Supported content types include ProjectImage, Description, and VideoUrl.

## Testing with Postman

1. Import the collection into Postman
2. Set the base URL variable to `http://localhost:3000/api/v1`
3. Add authentication headers if required
4. Test each endpoint with the provided examples

## Testing with curl

All examples above use curl commands that can be run directly in the terminal. Make sure to:
1. Replace `localhost:3000` with your actual server URL
2. Update project IDs and image IDs to match your data
3. Include proper authentication headers if required

## Swagger Documentation
Truy cập: `http://localhost:3000/swagger` để xem documentation đầy đủ. 
# Project summary
Sample spring app, deployed on EC2 with terraform. Uses H2 in memory DB. 

# Author API Endpoints 

REST API for managing author records. 

## Endpoints

### Get Author
```
GET /author?author_id={id}
```

Returns first author matching the author_id.

**Response:**
```json
{
  "author_id": 1,
  "name": "Billy Baker"
}
```

---

### Create Author
```
POST /author
```

**Request:**
```json
{
  "author_id": 1,
  "name": "Billy Baker"
}
```

**Response:**
```json
{
  "author_id": 1,
  "name": "Billy Baker"
}
```
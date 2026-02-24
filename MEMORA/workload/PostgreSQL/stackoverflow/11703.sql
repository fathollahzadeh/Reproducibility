
WITH Benchmark AS (
  SELECT 
    p.Id AS PostId,
    p.Title,
    u.DisplayName AS Owner,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    COUNT(c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
  FROM 
    Posts p
  LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
  LEFT JOIN 
    Comments c ON p.Id = c.PostId
  LEFT JOIN 
    Votes v ON p.Id = v.PostId
  WHERE 
    p.PostTypeId = 1 
  GROUP BY 
    p.Id, p.Title, u.DisplayName, p.CreationDate, p.ViewCount, p.Score
)
SELECT 
  PostId,
  Title,
  Owner,
  CreationDate,
  ViewCount,
  Score,
  CommentCount,
  UpVotes,
  DownVotes,
  (UpVotes - DownVotes) AS NetVotes
FROM 
  Benchmark
ORDER BY 
  ViewCount DESC, Score DESC
LIMIT 10;

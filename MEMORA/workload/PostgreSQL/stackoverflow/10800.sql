WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes,
        p.CreationDate,
        p.LastActivityDate,
        pt.Name AS PostTypeName,
        u.DisplayName AS OwnerDisplayName
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
    JOIN PostTypes pt ON p.PostTypeId = pt.Id
    JOIN Users u ON p.OwnerUserId = u.Id
)
SELECT 
    PostId,
    Title,
    Score,
    ViewCount,
    AnswerCount,
    CommentCount,
    UpVotes,
    DownVotes,
    CreationDate,
    LastActivityDate,
    PostTypeName,
    OwnerDisplayName
FROM 
    PostStats
ORDER BY 
    Score DESC, 
    ViewCount DESC
LIMIT 100;
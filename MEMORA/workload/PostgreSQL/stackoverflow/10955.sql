
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        p.Score,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        pt.Name AS PostType,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.AnswerCount, p.Score, u.DisplayName, pt.Name
)
SELECT 
    PostId,
    Title,
    CreationDate,
    ViewCount,
    AnswerCount,
    CommentCount,
    Score,
    OwnerDisplayName,
    PostType,
    UpVotes,
    DownVotes
FROM 
    PostStats
ORDER BY 
    Score DESC, ViewCount DESC
LIMIT 100;

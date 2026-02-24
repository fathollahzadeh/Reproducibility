
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COALESCE(a.AnswerCount, 0) AS AnswerCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(v.UpVoteCount, 0) AS UpVoteCount,
        COALESCE(v.DownVoteCount, 0) AS DownVoteCount,
        p.CreationDate,
        p.LastActivityDate,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT 
            ParentId, 
            COUNT(*) AS AnswerCount 
         FROM 
            Posts 
         WHERE 
            PostTypeId = 2 
         GROUP BY 
            ParentId) a ON p.Id = a.ParentId
    LEFT JOIN 
        (SELECT 
            PostId, 
            COUNT(*) AS CommentCount 
         FROM 
            Comments 
         GROUP BY 
            PostId) c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT 
            PostId, 
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
         FROM 
            Votes 
         GROUP BY 
            PostId) v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 YEAR' 
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.Score,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CommentCount,
    ps.UpVoteCount,
    ps.DownVoteCount,
    ps.CreationDate,
    ps.LastActivityDate,
    u.DisplayName AS OwnerDisplayName
FROM 
    PostStats ps
JOIN 
    Users u ON ps.OwnerUserId = u.Id
ORDER BY 
    ps.CreationDate DESC;

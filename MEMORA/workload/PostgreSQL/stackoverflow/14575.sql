
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        AVG(v.vote_count) AS AvgVoteCount,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS vote_count
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2022-01-01' 
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId
)

SELECT 
    ph.PostId,
    ph.Title,
    ph.CommentCount,
    ph.AnswerCount,
    ph.AvgVoteCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation,
    ROW_NUMBER() OVER (ORDER BY ph.AvgVoteCount DESC) AS Rank
FROM 
    PostStats ph
JOIN 
    Users u ON ph.OwnerUserId = u.Id
ORDER BY 
    ph.CommentCount DESC, ph.AvgVoteCount DESC
LIMIT 100;

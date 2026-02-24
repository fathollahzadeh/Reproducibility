
WITH PostSummary AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        CONCAT(u.DisplayName, ' (Reputation: ', u.Reputation, ')') AS OwnerInfo
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= '2023-01-01'  
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, u.DisplayName, u.Reputation
)
SELECT 
    PostId,
    Title,
    CreationDate,
    ViewCount,
    Score,
    CommentCount,
    VoteCount,
    OwnerInfo,
    ROUND((Score / NULLIF(ViewCount, 0)) * 100, 2) AS ScorePer100Views
FROM 
    PostSummary
ORDER BY 
    Score DESC, ViewCount DESC;


WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerName,
        p.Score,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName, p.Score
), 
HighestScoringPosts AS (
    SELECT 
        PostId, 
        Title, 
        CreationDate, 
        OwnerName, 
        Score, 
        CommentCount,
        RANK() OVER (ORDER BY Score DESC) AS ScoreRank
    FROM 
        RecentPosts
), 
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        SUM(u.Reputation) AS TotalReputation
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
)
SELECT 
    h.PostId,
    h.Title,
    h.OwnerName,
    h.CreationDate,
    h.Score,
    h.CommentCount,
    ur.TotalReputation,
    CASE 
        WHEN h.Score > 100 THEN 'High Scorer'
        WHEN h.Score BETWEEN 50 AND 100 THEN 'Moderate Scorer'
        ELSE 'Low Scorer'
    END AS ScoreCategory
FROM 
    HighestScoringPosts h
LEFT JOIN 
    UserReputation ur ON h.OwnerName = (SELECT DisplayName FROM Users WHERE Id = ur.UserId)
WHERE 
    h.ScoreRank <= 10
ORDER BY 
    h.Score DESC
LIMIT 10;

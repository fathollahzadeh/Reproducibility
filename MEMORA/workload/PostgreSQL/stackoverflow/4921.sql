
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank
    FROM 
        Posts p 
    WHERE 
        p.PostTypeId = 1  
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        rp.CreationDate,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(a.AnswerCount, 0) AS AnswerCount,
        CASE 
            WHEN rp.Score >= 50 THEN 'High Scoring'
            WHEN rp.Score BETWEEN 20 AND 49 THEN 'Medium Scoring'
            ELSE 'Low Scoring'
        END AS ScoreCategory,
        rp.UserRank
    FROM 
        RankedPosts rp
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS CommentCount 
        FROM Comments 
        GROUP BY PostId
    ) c ON rp.PostId = c.PostId
    LEFT JOIN (
        SELECT ParentId AS PostId, COUNT(*) AS AnswerCount 
        FROM Posts 
        WHERE PostTypeId = 2 
        GROUP BY ParentId
    ) a ON rp.PostId = a.PostId
)
SELECT 
    pd.Title,
    pd.ViewCount,
    pd.Score,
    pd.CommentCount,
    pd.AnswerCount,
    pd.ScoreCategory,
    u.DisplayName AS OwnerDisplayName,
    COALESCE(b.BadgeCount, 0) AS BadgeCount
FROM 
    PostDetails pd
JOIN Users u ON pd.PostId = u.Id
LEFT JOIN (
    SELECT UserId, COUNT(*) AS BadgeCount 
    FROM Badges 
    WHERE Class = 1 
    GROUP BY UserId
) b ON u.Id = b.UserId
WHERE 
    pd.UserRank <= 3 
ORDER BY 
    pd.ViewCount DESC, 
    pd.Score DESC
LIMIT 100;

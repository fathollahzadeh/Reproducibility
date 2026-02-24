WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        u.Reputation AS UserReputation
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score >= 10
),
PostWithComments AS (
    SELECT 
        r.PostId,
        r.Title,
        r.Score,
        r.ViewCount,
        r.UserReputation,
        COALESCE(c.CommentCount, 0) as CommentCount
    FROM 
        RankedPosts r
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount 
         FROM Comments 
         GROUP BY PostId) c ON r.PostId = c.PostId
),
FinalResults AS (
    SELECT 
        p.*,
        CASE 
            WHEN UserReputation > 1000 THEN 'High Reputation'
            WHEN UserReputation BETWEEN 501 AND 1000 THEN 'Medium Reputation'
            ELSE 'Low Reputation'
        END AS ReputationCategory
    FROM 
        PostWithComments p
    WHERE 
        p.CommentCount > 5
)
SELECT 
    f.PostId,
    f.Title,
    f.Score,
    f.ViewCount,
    f.ReputationCategory
FROM 
    FinalResults f
ORDER BY 
    f.Score DESC, 
    f.ViewCount DESC
LIMIT 10;

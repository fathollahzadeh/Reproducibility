WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, p.Score
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        COALESCE(SUM(b.Class), 0) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation, u.DisplayName
),
TopScoringPosts AS (
    SELECT 
        rp.Title,
        ur.DisplayName,
        rp.Score,
        rp.CommentCount,
        RANK() OVER (ORDER BY rp.Score DESC) AS ScoreRank
    FROM 
        RankedPosts rp
    JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.UserId
    WHERE 
        rp.PostRank = 1 
        AND ur.Reputation > 1000
)
SELECT 
    t.Title AS TopPostTitle,
    t.DisplayName AS PostOwner,
    t.Score AS PostScore,
    t.CommentCount,
    CASE 
        WHEN t.Score > 100 THEN 'High Score'
        WHEN t.Score BETWEEN 50 AND 100 THEN 'Medium Score'
        ELSE 'Low Score'
    END AS ScoreCategory
FROM 
    TopScoringPosts t
WHERE 
    t.ScoreRank <= 10
ORDER BY 
    t.Score DESC;
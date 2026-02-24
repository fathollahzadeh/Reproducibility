WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= '2023-01-01'
),
UserScores AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.CreationDate >= '2023-01-01'
    GROUP BY 
        u.Id, u.DisplayName
),
HighScorers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.TotalScore
    FROM 
        UserScores us
    WHERE 
        us.TotalScore > 1000
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.CommentCount,
    hs.DisplayName AS TopUser,
    hs.TotalScore
FROM 
    RankedPosts rp
LEFT JOIN 
    HighScorers hs ON rp.OwnerUserId = hs.UserId
WHERE 
    rp.Rank = 1
ORDER BY 
    rp.Score DESC
LIMIT 10;
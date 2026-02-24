
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COALESCE(
            (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 
            0) AS CommentCount,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= '2023-10-01 12:34:56'::timestamp - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostScores AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        ur.Reputation,
        ur.BadgeCount,
        CASE 
            WHEN rp.Score >= 100 THEN 'High'
            WHEN rp.Score BETWEEN 50 AND 99 THEN 'Medium'
            ELSE 'Low' 
        END AS ScoreCategory
    FROM 
        RankedPosts rp
    JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.UserId
    WHERE 
        rp.Rank = 1
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.Score,
    ps.ViewCount,
    ps.CommentCount,
    ps.Reputation AS UserReputation,
    ps.BadgeCount,
    ps.ScoreCategory
FROM 
    PostScores ps
WHERE 
    ps.Reputation > 1000
ORDER BY 
    ps.Score DESC, ps.ViewCount ASC
OFFSET 5 ROWS
FETCH NEXT 10 ROWS ONLY;

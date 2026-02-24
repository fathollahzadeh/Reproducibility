
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate > CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(b.Class), 0) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        ur.Reputation,
        ur.TotalBadges
    FROM 
        RankedPosts rp
    JOIN 
        UserReputation ur ON rp.PostId = ur.UserId
    WHERE 
        rp.UserRank = 1 
        AND ur.Reputation > 100
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.Score,
    CASE 
        WHEN tp.ViewCount IS NULL THEN 'Views not available'
        ELSE CAST(tp.ViewCount AS TEXT) || ' views'
    END AS ViewDetails,
    CASE 
        WHEN tp.TotalBadges = 0 THEN 'No badges earned'
        ELSE CAST(tp.TotalBadges AS TEXT) || ' badges earned'
    END AS BadgeInfo
FROM 
    TopPosts tp
WHERE 
    tp.Score >= (SELECT AVG(Score) FROM Posts) 
    AND tp.CommentCount > (
        SELECT AVG(CommentCount) 
        FROM (
            SELECT COUNT(*) AS CommentCount 
            FROM Comments 
            GROUP BY PostId
        ) AS CommentCounts
    )
ORDER BY 
    tp.Score DESC
LIMIT 10;

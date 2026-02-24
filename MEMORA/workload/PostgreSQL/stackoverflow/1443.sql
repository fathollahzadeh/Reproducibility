WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.AnswerCount,
        p.ViewCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year' 
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
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.AnswerCount,
    rp.ViewCount,
    rp.CommentCount,
    ur.Reputation,
    ur.TotalBadges
FROM 
    RankedPosts rp
JOIN 
    UserReputation ur ON rp.PostId IN (SELECT b.UserId FROM Badges b WHERE b.Date >= cast('2024-10-01' as date) - INTERVAL '6 months')
WHERE 
    rp.PostRank = 1
AND 
    (ur.Reputation > 1000 OR ur.TotalBadges > 5)
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC
LIMIT 50;
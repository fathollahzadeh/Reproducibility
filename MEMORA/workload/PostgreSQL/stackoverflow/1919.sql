
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.OwnerUserId
), UserReputations AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        CASE 
            WHEN u.Reputation > 1000 THEN 'High'
            WHEN u.Reputation BETWEEN 100 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS ReputationCategory
    FROM 
        Users u
), RecentPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        ur.ReputationCategory
    FROM 
        RankedPosts rp
    JOIN 
        UserReputations ur ON rp.OwnerUserId = ur.UserId
    WHERE 
        rp.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '30 days'
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ReputationCategory,
    COALESCE(MIN(v.BountyAmount), 0) AS LowestBounty,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId IN (2, 3)) AS VoteCount
FROM 
    RecentPosts rp
LEFT JOIN 
    Votes v ON rp.PostId = v.PostId
GROUP BY 
    rp.PostId, rp.Title, rp.Score, rp.ReputationCategory
HAVING 
    COUNT(DISTINCT v.UserId) > 5
ORDER BY 
    rp.Score DESC, rp.Title ASC;

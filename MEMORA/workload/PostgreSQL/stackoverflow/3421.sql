
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9)  
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.OwnerUserId
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
UserStats AS (
    SELECT 
        ur.UserId,
        ur.Reputation,
        ur.BadgeCount,
        COALESCE(rp.Score, 0) AS HighestPostScore,
        COALESCE(rp.CommentCount, 0) AS TotalComments,
        COALESCE(rp.TotalBounty, 0) AS TotalBounty,
        ROW_NUMBER() OVER (ORDER BY ur.Reputation DESC) AS ReputationRank
    FROM 
        UserReputation ur
    LEFT JOIN 
        (SELECT OwnerUserId, MAX(Score) AS Score, SUM(CommentCount) AS CommentCount, SUM(TotalBounty) AS TotalBounty
         FROM RankedPosts
         GROUP BY OwnerUserId) rp ON ur.UserId = rp.OwnerUserId
)
SELECT 
    us.UserId,
    us.Reputation,
    us.BadgeCount,
    us.HighestPostScore,
    us.TotalComments,
    us.TotalBounty,
    CASE 
        WHEN us.Reputation > 1000 THEN 'Gold'
        WHEN us.Reputation BETWEEN 500 AND 1000 THEN 'Silver'
        ELSE 'Bronze'
    END AS ReputationTier,
    (SELECT COUNT(*) FROM Posts p WHERE p.OwnerUserId = us.UserId) AS PostCount,
    (SELECT STRING_AGG(DISTINCT t.TagName, ', ') 
     FROM Posts p 
     JOIN Tags t ON p.Tags LIKE CONCAT('%', t.TagName, '%')
     WHERE p.OwnerUserId = us.UserId) AS UsedTags
FROM 
    UserStats us
WHERE 
    us.ReputationRank <= 10
ORDER BY 
    us.Reputation DESC;

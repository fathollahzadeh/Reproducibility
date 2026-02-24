
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
), UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON v.UserId = u.Id AND v.PostId = p.Id
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.Reputation
), TopContributors AS (
    SELECT 
        ur.UserId, 
        ur.Reputation, 
        ur.PostCount,
        ur.TotalBounty,
        ROW_NUMBER() OVER (ORDER BY ur.Reputation DESC, ur.PostCount DESC) AS ContributorRank
    FROM 
        UserReputation ur
    WHERE 
        ur.PostCount > 5
)
SELECT 
    tp.UserId, 
    tp.Reputation, 
    tp.PostCount, 
    tp.TotalBounty,
    (SELECT p.Title FROM Posts p WHERE p.OwnerUserId = tp.UserId AND p.Score = (SELECT MAX(Score) FROM Posts WHERE OwnerUserId = tp.UserId)) AS TopPostTitle,
    (SELECT p.Score FROM Posts p WHERE p.OwnerUserId = tp.UserId AND p.Score = (SELECT MAX(Score) FROM Posts WHERE OwnerUserId = tp.UserId)) AS TopPostScore,
    (SELECT p.ViewCount FROM Posts p WHERE p.OwnerUserId = tp.UserId AND p.Score = (SELECT MAX(Score) FROM Posts WHERE OwnerUserId = tp.UserId)) AS TopPostViewCount
FROM 
    TopContributors tp
WHERE 
    tp.ContributorRank <= 10
ORDER BY 
    tp.Reputation DESC, 
    tp.PostCount DESC;

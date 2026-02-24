
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank,
        COUNT(v.Id) AS VoteCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 
    LEFT JOIN 
        Tags t ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.OwnerUserId, p.Title, p.CreationDate, p.Score, p.ViewCount
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate
    FROM 
        Users u
    WHERE 
        u.Reputation >= (SELECT AVG(Reputation) FROM Users)
    ORDER BY 
        u.Reputation DESC
    LIMIT 10
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    COALESCE(rp.Title, 'No Posts') AS TopPostTitle,
    COALESCE(rp.Score, 0) AS TopPostScore,
    COALESCE(rp.ViewCount, 0) AS TopPostViewCount,
    COALESCE(rp.Tags, 'No Tags') AS TopPostTags,
    COALESCE(CAST(rp.Rank AS VARCHAR), 'N/A') AS PostRank,
    COALESCE(SUM(b.Class), 0) AS TotalBadges
FROM 
    TopUsers tu
LEFT JOIN 
    RankedPosts rp ON tu.UserId = rp.OwnerUserId AND rp.Rank = 1
LEFT JOIN 
    Badges b ON tu.UserId = b.UserId
GROUP BY 
    tu.UserId, tu.DisplayName, rp.Title, rp.Score, rp.ViewCount, rp.Tags, rp.Rank
ORDER BY 
    TotalBadges DESC, TopPostScore DESC
LIMIT 5;


WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM Posts p
    WHERE p.CreationDate >= CAST('2024-10-01 12:34:56' AS timestamp) - INTERVAL '1 year'
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM Tags t
    JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY t.TagName
    HAVING COUNT(p.Id) > 5
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
        COUNT(DISTINCT p.Id) AS PostsCount,
        MAX(u.Reputation) AS Reputation
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
)
SELECT 
    rp.Title,
    rp.ViewCount,
    rp.Score,
    pt.TagName,
    ur.DisplayName AS UserDisplayName,
    ur.TotalBounty,
    ur.Reputation
FROM RankedPosts rp
JOIN PopularTags pt ON rp.Title LIKE '%' || pt.TagName || '%'
JOIN UserReputation ur ON rp.PostId = ur.UserId
WHERE rp.Rank <= 3
AND ur.Reputation > 1000
ORDER BY rp.Score DESC, rp.ViewCount DESC
LIMIT 10;

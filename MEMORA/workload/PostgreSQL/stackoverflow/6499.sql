WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        RANK() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PopularPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        DENSE_RANK() OVER (ORDER BY p.ViewCount DESC, p.Score DESC) AS PopularityRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
        AND p.PostTypeId = 1
)
SELECT 
    ru.DisplayName,
    ru.Reputation,
    ru.BadgeCount,
    pp.Title AS PopularPostTitle,
    pp.Score AS PostScore,
    pp.ViewCount AS PostViewCount,
    ru.UserRank,
    pp.PopularityRank
FROM 
    RankedUsers ru
JOIN 
    PopularPosts pp ON ru.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = pp.PostId)
WHERE 
    ru.UserRank <= 10
ORDER BY 
    ru.UserRank, pp.PopularityRank;
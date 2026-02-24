
WITH RecursiveUserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(vs.VoteCount), 0) AS TotalVotes,
        COALESCE(SUM(ps.ViewCount), 0) AS TotalViews,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY u.CreationDate DESC) AS rn
    FROM 
        Users u
    LEFT JOIN (
        SELECT 
            v.UserId, 
            COUNT(v.Id) AS VoteCount
        FROM 
            Votes v
        GROUP BY 
            v.UserId
    ) AS vs ON u.Id = vs.UserId
    LEFT JOIN Posts ps ON u.Id = ps.OwnerUserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
), 
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= (TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days')
    ORDER BY 
        p.CreationDate DESC
),
TopRankedUsers AS (
    SELECT 
        u.UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(p.ViewCount), 0) AS UserViews,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        RecursiveUserActivity u
    LEFT JOIN Posts p ON u.UserId = p.OwnerUserId
    GROUP BY 
        u.UserId, u.DisplayName, u.Reputation
    HAVING 
        COUNT(p.Id) > 0
)
SELECT 
    u.DisplayName AS TopUser,
    u.Reputation,
    SUM(p.ViewCount) AS TotalPostViews,
    COUNT(p.Id) AS TotalPosts,
    STRING_AGG(DISTINCT p.Title, ', ') AS RecentPostTitles
FROM 
    TopRankedUsers u
JOIN 
    Posts p ON u.UserId = p.OwnerUserId
GROUP BY 
    u.DisplayName, u.Reputation
HAVING 
    COUNT(p.Id) > 0
ORDER BY 
    u.Reputation DESC
LIMIT 10;

WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT b.Id) AS TotalBadges
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Badges b ON u.Id = b.UserId
    WHERE u.Reputation > 100
    GROUP BY u.Id, u.DisplayName
), RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalUpVotes,
        TotalDownVotes,
        TotalPosts,
        TotalBadges,
        RANK() OVER (ORDER BY TotalUpVotes - TotalDownVotes DESC, TotalPosts DESC) AS UserRank
    FROM UserVoteStats
),
RecentPopularPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC, p.CreationDate DESC) AS PopularityRank
    FROM Posts p
    WHERE p.Score > 10 AND p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
EligibleBadges AS (
    SELECT 
        b.UserId, 
        COUNT(*) AS BadgeCount 
    FROM Badges b 
    WHERE b.Class = 2  
    GROUP BY b.UserId
)
SELECT 
    ru.DisplayName,
    ru.TotalUpVotes,
    ru.TotalDownVotes,
    ru.TotalPosts,
    COALESCE(eb.BadgeCount, 0) AS SilverBadges,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score
FROM RankedUsers ru
LEFT JOIN EligibleBadges eb ON ru.UserId = eb.UserId
LEFT JOIN RecentPopularPosts rp ON ru.UserId = (
    SELECT OwnerUserId 
    FROM Posts 
    WHERE Id = rp.PostId
    LIMIT 1
)
WHERE ru.UserRank <= 10
ORDER BY ru.UserRank, rp.Score DESC;
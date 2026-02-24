WITH UserActivity AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(b.TotalBounties, 0) AS TotalBounties,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS RecentRank
    FROM Posts p
    LEFT JOIN (
        SELECT
            PostId,
            SUM(BountyAmount) AS TotalBounties
        FROM Votes
        WHERE VoteTypeId IN (8, 9) 
        GROUP BY PostId
    ) b ON p.Id = b.PostId
),
RecentPosts AS (
    SELECT
        PostId,
        Title,
        CreationDate,
        Score,
        TotalBounties,
        RecentRank
    FROM PostStatistics
    WHERE RecentRank <= 10
)
SELECT
    ua.UserId,
    ua.DisplayName,
    ua.TotalBounty,
    ua.TotalPosts,
    ua.TotalComments,
    COUNT(rp.PostId) AS PostsInLastMonth,
    AVG(rp.Score) AS AvgPostScore
FROM UserActivity ua
LEFT JOIN RecentPosts rp ON ua.UserId = rp.PostId
WHERE ua.TotalPosts > 0
GROUP BY ua.UserId, ua.DisplayName, ua.TotalBounty, ua.TotalPosts, ua.TotalComments
HAVING AVG(rp.Score) > 10 OR COUNT(rp.PostId) > 3
ORDER BY ua.TotalBounty DESC, ua.TotalPosts DESC;
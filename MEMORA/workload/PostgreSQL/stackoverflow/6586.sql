
WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.PostTypeId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.LastActivityDate DESC) AS RecentPostRank
    FROM Posts p
    WHERE p.CreationDate >= '2024-10-01 12:34:56'::timestamp - INTERVAL '30 days'
),
PostSummary AS (
    SELECT 
        u.UserId,
        u.DisplayName,
        COUNT(p.PostId) AS TotalPosts,
        COUNT(c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM RankedUsers u
    LEFT JOIN RecentPosts p ON u.UserId = p.OwnerUserId
    LEFT JOIN Comments c ON p.PostId = c.PostId
    LEFT JOIN Votes v ON p.PostId = v.PostId
    GROUP BY u.UserId, u.DisplayName
)
SELECT 
    ps.UserId,
    ps.DisplayName,
    ps.TotalPosts,
    ps.TotalComments,
    ps.TotalUpVotes,
    ps.TotalDownVotes,
    CASE 
        WHEN ps.TotalPosts > 0 THEN ROUND((ps.TotalUpVotes * 1.0 / GREATEST(ps.TotalPosts, 1)) * 100, 2)
        ELSE 0
    END AS UpVotePercentage,
    CASE 
        WHEN ps.TotalDownVotes > 0 THEN ROUND((ps.TotalDownVotes * 1.0 / GREATEST(ps.TotalPosts, 1)) * 100, 2)
        ELSE 0
    END AS DownVotePercentage,
    ur.ReputationRank
FROM PostSummary ps
JOIN RankedUsers ur ON ps.UserId = ur.UserId
WHERE ur.ReputationRank <= 50
ORDER BY ur.ReputationRank, ps.TotalPosts DESC;

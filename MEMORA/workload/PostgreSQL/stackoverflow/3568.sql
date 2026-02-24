WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
),

PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM Posts p
    GROUP BY p.OwnerUserId
),

RecentVotes AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM Votes v
    WHERE v.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY v.PostId
),

PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 24 THEN 1 END) AS EditsCount
    FROM PostHistory ph
    GROUP BY ph.PostId
)

SELECT 
    u.DisplayName,
    u.Reputation,
    ps.TotalPosts,
    ps.TotalViews,
    ps.TotalScore,
    COALESCE(rv.UpVotes, 0) AS RecentUpVotes,
    COALESCE(rv.DownVotes, 0) AS RecentDownVotes,
    COALESCE(phe.CloseReopenCount, 0) AS CloseReopenCount,
    COALESCE(phe.EditsCount, 0) AS EditsCount,
    ur.ReputationRank
FROM Users u
LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
LEFT JOIN RecentVotes rv ON ps.OwnerUserId = rv.PostId
LEFT JOIN PostHistorySummary phe ON ps.OwnerUserId = phe.PostId
JOIN UserReputation ur ON u.Id = ur.UserId
WHERE u.Reputation > (SELECT AVG(Reputation) FROM Users WHERE Reputation IS NOT NULL)
ORDER BY ur.ReputationRank;
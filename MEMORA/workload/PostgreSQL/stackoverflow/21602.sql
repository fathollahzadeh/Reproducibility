
WITH UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(v.VoteCount, 0)) AS UpVotes,
        SUM(COALESCE(v.DownVoteCount, 0)) AS DownVotes,
        SUM(CASE WHEN p.CreationDate < TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' THEN 1 ELSE 0 END) AS OldPostsCount
    FROM Users u
    LEFT JOIN (
        SELECT 
            OwnerUserId, 
            Id, 
            CreationDate
        FROM Posts
    ) p ON u.Id = p.OwnerUserId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS VoteCount,
            COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVoteCount
        FROM Votes
        GROUP BY PostId
    ) v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
UserBadges AS (
    SELECT 
        UserId,
        STRING_AGG(Name, ', ') AS BadgeNames,
        COUNT(*) AS BadgeCount
    FROM Badges
    GROUP BY UserId
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseStatusChanges,
        MAX(ph.CreationDate) AS LastHistoryDate
    FROM PostHistory ph
    WHERE ph.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY ph.PostId
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        COALESCE(rp.CloseStatusChanges, 0) AS CloseStatusChangeCount
    FROM Posts p
    LEFT JOIN RecentPostHistory rp ON p.Id = rp.PostId
)
SELECT 
    ue.UserId,
    ue.DisplayName,
    ue.Reputation,
    ue.PostCount,
    ub.BadgeNames,
    ub.BadgeCount,
    ps.PostId,
    ps.Title,
    ps.Score,
    ps.ViewCount,
    ps.CreationDate,
    ps.PostRank,
    ps.CloseStatusChangeCount,
    CASE 
        WHEN ue.Reputation > 1000 THEN 'Experienced User'
        WHEN ue.PostCount > 50 THEN 'Active Contributor'
        ELSE 'Newcomer'
    END AS UserType
FROM UserEngagement ue
LEFT JOIN UserBadges ub ON ue.UserId = ub.UserId
JOIN PostStatistics ps ON ue.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = ps.PostId)
WHERE ue.Reputation > 100 AND (ps.Score IS NOT NULL OR ps.ViewCount > 50)
ORDER BY ue.Reputation DESC, ps.ViewCount DESC
LIMIT 10;

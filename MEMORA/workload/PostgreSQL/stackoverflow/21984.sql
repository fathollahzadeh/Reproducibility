WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation, 
        ROW_NUMBER() OVER (PARTITION BY CASE WHEN u.Reputation > 1000 THEN 'High' 
                                              WHEN u.Reputation > 100 THEN 'Medium' 
                                              ELSE 'Low' END 
                             ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.OwnerUserId,
        DENSE_RANK() OVER (ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
UserBadges AS (
    SELECT 
        b.UserId, 
        COUNT(b.Id) AS BadgeCount, 
        MAX(b.Class) AS HighestBadgeClass
    FROM Badges b
    GROUP BY b.UserId
),
VoteSummary AS (
    SELECT 
        v.PostId, 
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM Votes v
    JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY v.PostId
),
PostClosure AS (
    SELECT 
        p.Id AS PostId, 
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount
    FROM Posts p
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId 
    GROUP BY p.Id
)
SELECT 
    r.UserId, 
    r.DisplayName, 
    r.Reputation, 
    r.ReputationRank, 
    COALESCE(b.BadgeCount, 0) AS BadgeCount, 
    COALESCE(b.HighestBadgeClass, 0) AS HighestBadgeClass, 
    rp.PostId, 
    rp.Title AS RecentPostTitle, 
    rp.CreationDate AS RecentPostDate, 
    ps.CloseCount AS TotalCloseCount, 
    ps.ReopenCount AS TotalReopenCount,
    COALESCE(vs.TotalUpvotes, 0) AS TotalUpvotes,
    COALESCE(vs.TotalDownvotes, 0) AS TotalDownvotes
FROM RankedUsers r
LEFT JOIN UserBadges b ON r.UserId = b.UserId
LEFT JOIN RecentPosts rp ON rp.OwnerUserId = r.UserId
LEFT JOIN PostClosure ps ON rp.PostId = ps.PostId
LEFT JOIN VoteSummary vs ON rp.PostId = vs.PostId
WHERE r.ReputationRank <= 10
  AND (b.BadgeCount IS NULL OR b.BadgeCount > 0)
ORDER BY r.Reputation DESC, rp.CreationDate DESC
FETCH FIRST 50 ROWS ONLY;
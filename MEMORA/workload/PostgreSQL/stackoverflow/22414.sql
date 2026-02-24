WITH UsersWithBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
PostsWithVoteCounts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 4 THEN 1 ELSE 0 END), 0) AS OffensiveVotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, p.Title
),
ClosedPostHistory AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstCloseDate,
        MAX(ph.CreationDate) AS LastCloseDate,
        COUNT(ph.Id) AS CloseCount
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10
    GROUP BY ph.PostId
),
UserScoreAndPostCounts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        COALESCE(SUM(CASE WHEN p.Score > 0 THEN p.Score ELSE 0 END), 0) AS PositiveScore,
        COALESCE(SUM(CASE WHEN p.Score < 0 THEN p.Score ELSE 0 END), 0) AS NegativeScore
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
)

SELECT 
    u.UserId,
    u.DisplayName,
    u.BadgeCount,
    u.GoldBadges,
    u.SilverBadges,
    u.BronzeBadges,
    p.PostId,
    p.Title,
    p.UpVotes,
    p.DownVotes,
    p.OffensiveVotes,
    c.FirstCloseDate,
    c.LastCloseDate,
    c.CloseCount,
    pc.PostCount,
    pc.PositiveScore,
    pc.NegativeScore
FROM UsersWithBadges u
JOIN PostsWithVoteCounts p ON u.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = p.PostId AND OwnerUserId IS NOT NULL LIMIT 1)
LEFT JOIN ClosedPostHistory c ON p.PostId = c.PostId
LEFT JOIN UserScoreAndPostCounts pc ON u.UserId = pc.UserId
WHERE u.BadgeCount > 5
AND (p.UpVotes + p.DownVotes) > 10
AND COALESCE(c.CloseCount, 0) = 0
ORDER BY u.DisplayName, p.UpVotes DESC, pc.PostCount DESC;

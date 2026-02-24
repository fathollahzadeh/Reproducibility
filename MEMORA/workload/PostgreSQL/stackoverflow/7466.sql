WITH UserBadges AS (
    SELECT u.Id AS UserId, COUNT(b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostStats AS (
    SELECT p.OwnerUserId, COUNT(p.Id) AS PostCount, SUM(p.Score) AS TotalScore, SUM(p.ViewCount) AS TotalViews
    FROM Posts p
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY p.OwnerUserId
),
VoteSummary AS (
    SELECT v.UserId, COUNT(v.Id) AS VoteCount, SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpvoteCount
    FROM Votes v
    JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY v.UserId
),
UserPerformance AS (
    SELECT u.Id, u.DisplayName, COALESCE(ub.BadgeCount, 0) AS BadgeCount,
           COALESCE(ps.PostCount, 0) AS PostCount, COALESCE(ps.TotalScore, 0) AS TotalScore,
           COALESCE(ps.TotalViews, 0) AS TotalViews, COALESCE(vs.VoteCount, 0) AS VoteCount,
           COALESCE(vs.UpvoteCount, 0) AS UpvoteCount
    FROM Users u
    LEFT JOIN UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
    LEFT JOIN VoteSummary vs ON u.Id = vs.UserId
)
SELECT u.DisplayName, u.BadgeCount, u.PostCount, u.TotalScore, u.TotalViews, u.VoteCount, u.UpvoteCount
FROM UserPerformance u
WHERE u.PostCount > 0
ORDER BY u.TotalScore DESC, u.VoteCount DESC
LIMIT 10;
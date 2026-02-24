WITH UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostVoteSummary AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= '2021-01-01'
    GROUP BY p.Id, p.OwnerUserId
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        ps.VoteCount,
        ps.UpVotes,
        ps.DownVotes,
        ub.BadgeCount AS UserBadgeCount,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges
    FROM Posts p
    INNER JOIN PostVoteSummary ps ON p.Id = ps.PostId
    LEFT JOIN UserBadgeCounts ub ON ub.UserId = ps.OwnerUserId
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.ViewCount,
    ps.VoteCount,
    ps.UpVotes,
    ps.DownVotes,
    COALESCE(ps.UserBadgeCount, 0) AS UserBadgeCount,
    COALESCE(ps.GoldBadges, 0) AS GoldBadges,
    COALESCE(ps.SilverBadges, 0) AS SilverBadges,
    COALESCE(ps.BronzeBadges, 0) AS BronzeBadges
FROM PostStats ps
WHERE ps.ViewCount > 1000
ORDER BY ps.UpVotes DESC, ps.ViewCount DESC
LIMIT 50;

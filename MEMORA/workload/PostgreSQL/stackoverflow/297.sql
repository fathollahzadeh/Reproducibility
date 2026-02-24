
WITH UserBadges AS (
    SELECT 
        UserId, 
        COUNT(*) AS BadgeCount,
        SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS GoldCount,
        SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS SilverCount,
        SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS BronzeCount
    FROM Badges
    GROUP BY UserId
), PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY p.Id, p.OwnerUserId
), RankedPosts AS (
    SELECT 
        ps.PostId,
        ps.OwnerUserId,
        ps.CommentCount,
        ps.UpVotes,
        ps.DownVotes,
        RANK() OVER (PARTITION BY ps.OwnerUserId ORDER BY ps.UpVotes - ps.DownVotes DESC) AS Rank
    FROM PostStats ps
)

SELECT 
    u.DisplayName,
    u.Reputation,
    u.CreationDate,
    COALESCE(ub.BadgeCount, 0) AS TotalBadges,
    COALESCE(ub.GoldCount, 0) AS GoldBadges,
    COALESCE(ub.SilverCount, 0) AS SilverBadges,
    COALESCE(ub.BronzeCount, 0) AS BronzeBadges,
    rp.PostId,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    rp.Rank
FROM Users u
LEFT JOIN UserBadges ub ON u.Id = ub.UserId
LEFT JOIN RankedPosts rp ON u.Id = rp.OwnerUserId
WHERE u.Reputation > 1000
      AND (ub.BadgeCount IS NOT NULL OR rp.PostId IS NOT NULL)
      AND (rp.Rank <= 5 OR rp.PostId IS NULL)
ORDER BY u.Reputation DESC, rp.UpVotes DESC NULLS LAST;

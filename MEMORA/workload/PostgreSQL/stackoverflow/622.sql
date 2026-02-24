
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RankByUser
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        AVG(COALESCE(p.ViewCount, 0)) AS AvgPostViewCount,
        SUM(CASE WHEN bh.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN bh.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN bh.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges bh ON u.Id = bh.UserId
    GROUP BY u.Id, u.DisplayName
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.AvgPostViewCount,
    ua.GoldBadges,
    ua.SilverBadges,
    ua.BronzeBadges,
    rp.Title,
    rp.CreationDate,
    rp.CommentCount,
    rp.UpVoteCount,
    rp.DownVoteCount
FROM UserActivity ua
JOIN RankedPosts rp ON ua.UserId = rp.OwnerUserId
WHERE ua.AvgPostViewCount > 50
ORDER BY ua.GoldBadges DESC, ua.SilverBadges DESC, ua.BronzeBadges DESC, rp.UpVoteCount DESC
LIMIT 10
OFFSET 0;


WITH RecentPosts AS (
    SELECT p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.PostTypeId, p.AcceptedAnswerId,
           COUNT(c.Id) AS CommentCount,
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days'
    GROUP BY p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.PostTypeId, p.AcceptedAnswerId
),
UserActivity AS (
    SELECT u.Id AS UserId, u.DisplayName, COALESCE(SUM(p.ViewCount), 0) AS TotalViews,
           COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
           COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
           COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
TopContributors AS (
    SELECT ua.UserId, ua.DisplayName, ua.TotalViews, ua.GoldBadges, ua.SilverBadges, ua.BronzeBadges,
           ROW_NUMBER() OVER (ORDER BY ua.TotalViews DESC) AS Rank
    FROM UserActivity ua
    WHERE ua.TotalViews > 0
)
SELECT rp.Id AS PostId, rp.Title, rp.CreationDate, rp.CommentCount, rp.UpVotes, 
       rp.DownVotes, uc.DisplayName, uc.TotalViews, uc.GoldBadges, 
       uc.SilverBadges, uc.BronzeBadges
FROM RecentPosts rp
JOIN TopContributors uc ON rp.OwnerUserId = uc.UserId
WHERE rp.AcceptedAnswerId IS NOT NULL
  AND uc.Rank <= 10
ORDER BY rp.CreationDate DESC;

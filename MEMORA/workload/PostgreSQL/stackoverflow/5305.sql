
WITH UserDetails AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.UpVotes,
        u.DownVotes,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation, u.CreationDate, u.UpVotes, u.DownVotes
),
PostMetrics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AverageScore
    FROM Posts p
    GROUP BY p.OwnerUserId
),
UserPostDetails AS (
    SELECT 
        ud.UserId,
        ud.DisplayName,
        ud.Reputation,
        pm.PostCount,
        pm.Questions,
        pm.Answers,
        pm.TotalViews,
        pm.AverageScore,
        ud.GoldBadges,
        ud.SilverBadges,
        ud.BronzeBadges
    FROM UserDetails ud
    LEFT JOIN PostMetrics pm ON ud.UserId = pm.OwnerUserId
)
SELECT 
    upd.DisplayName,
    upd.Reputation,
    upd.PostCount,
    upd.Questions,
    upd.Answers,
    upd.TotalViews,
    upd.AverageScore,
    upd.GoldBadges,
    upd.SilverBadges,
    upd.BronzeBadges
FROM UserPostDetails upd
WHERE upd.PostCount > 10
ORDER BY upd.Reputation DESC, upd.TotalViews DESC
LIMIT 100;

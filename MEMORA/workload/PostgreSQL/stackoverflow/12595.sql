WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.Score IS NOT NULL THEN p.Score ELSE 0 END) AS TotalScore,
        SUM(CASE WHEN p.ViewCount IS NOT NULL THEN p.ViewCount ELSE 0 END) AS TotalViews,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
UserBadgeStats AS (
   SELECT 
       b.UserId,
       COUNT(b.Id) AS TotalBadges,
       SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
       SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
       SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
   FROM 
       Badges b
   GROUP BY 
       b.UserId
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.PostCount,
    ups.TotalScore,
    ups.TotalViews,
    ups.TotalUpVotes,
    ups.TotalDownVotes,
    ubs.TotalBadges,
    ubs.GoldBadges,
    ubs.SilverBadges,
    ubs.BronzeBadges
FROM 
    UserPostStats ups
LEFT JOIN 
    UserBadgeStats ubs ON ups.UserId = ubs.UserId
ORDER BY 
    ups.TotalScore DESC, ups.PostCount DESC
LIMIT 100;
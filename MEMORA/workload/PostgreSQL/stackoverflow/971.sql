WITH UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldCount,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverCount,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeCount
    FROM Badges b
    GROUP BY b.UserId
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(c.CommentCount, 0)) AS TotalComments
    FROM Posts p
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) c ON p.Id = c.PostId
    GROUP BY p.OwnerUserId
),
RankedUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        COALESCE(ub.GoldCount, 0) AS GoldBadges,
        COALESCE(ub.SilverCount, 0) AS SilverBadges,
        COALESCE(ub.BronzeCount, 0) AS BronzeBadges,
        ps.PostCount,
        ps.TotalScore,
        ps.TotalComments,
        RANK() OVER (ORDER BY COALESCE(ps.TotalScore, 0) DESC, ps.PostCount DESC) AS UserRank
    FROM Users u
    LEFT JOIN UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
)
SELECT 
    r.DisplayName,
    r.GoldBadges,
    r.SilverBadges,
    r.BronzeBadges,
    r.PostCount,
    r.TotalScore,
    r.TotalComments,
    CASE 
        WHEN r.UserRank <= 10 THEN 'Top Contributor'
        ELSE 'Contributor'
    END AS ContributorStatus,
    CASE 
        WHEN EXISTS (SELECT 1 FROM Posts p WHERE p.OwnerUserId = r.Id AND p.ClosedDate IS NOT NULL) THEN 'Has Closed Posts'
        ELSE 'No Closed Posts'
    END AS PostClosureStatus
FROM RankedUsers r
WHERE r.PostCount > 0
ORDER BY r.TotalScore DESC, r.PostCount DESC
LIMIT 20;

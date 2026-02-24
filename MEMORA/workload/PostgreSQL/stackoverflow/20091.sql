WITH RecursiveBadgeCounts AS (
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
UserPostActivity AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS TotalQuestions,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS TotalAnswers,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews
    FROM Posts p
    GROUP BY p.OwnerUserId
),
ActiveUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        COALESCE(rbc.BadgeCount, 0) AS BadgeCount,
        COALESCE(upa.TotalPosts, 0) AS TotalPosts,
        COALESCE(upa.TotalQuestions, 0) AS TotalQuestions,
        COALESCE(upa.TotalAnswers, 0) AS TotalAnswers,
        COALESCE(upa.TotalScore, 0) AS TotalScore,
        COALESCE(upa.TotalViews, 0) AS TotalViews
    FROM Users u
    LEFT JOIN RecursiveBadgeCounts rbc ON u.Id = rbc.UserId
    LEFT JOIN UserPostActivity upa ON u.Id = upa.OwnerUserId
    WHERE u.Reputation > 1000 
), 
RankedUsers AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY TotalScore DESC, TotalPosts DESC) AS ScoreRank,
        RANK() OVER (ORDER BY BadgeCount DESC) AS BadgeRank
    FROM ActiveUsers
)
SELECT 
    au.DisplayName,
    au.BadgeCount,
    au.TotalPosts,
    au.TotalQuestions,
    au.TotalAnswers,
    au.TotalScore,
    au.TotalViews,
    CASE 
        WHEN au.BadgeCount > 0 THEN 'Badge Holder'
        ELSE 'Novice'
    END AS UserType,
    CASE 
        WHEN ScoreRank <= 10 THEN 'Top Contributor'
        ELSE 'Regular Contributor'
    END AS ContributionLevel
FROM RankedUsers au
WHERE au.ScoreRank <= 50 
  AND au.BadgeRank <= 50
ORDER BY au.TotalScore DESC, au.BadgeCount DESC;
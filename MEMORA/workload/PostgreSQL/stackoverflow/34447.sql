
WITH RECURSIVE UserContribution AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
    GROUP BY u.Id, u.DisplayName
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges b
    GROUP BY b.UserId
),
PostsActivity AS (
    SELECT 
        p.OwnerUserId,
        p.CreationDate,
        CASE 
            WHEN COUNT(*) OVER (PARTITION BY p.OwnerUserId) > 10 THEN 'Active' 
            ELSE 'Inactive' 
        END AS FenstonRanking,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS ActivityRank
    FROM Posts p
)
SELECT 
    uc.UserId,
    uc.DisplayName,
    uc.TotalPosts,
    uc.TotalQuestions,
    uc.TotalAnswers,
    COALESCE(ub.GoldBadges, 0) AS GoldBadges,
    COALESCE(ub.SilverBadges, 0) AS SilverBadges,
    COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
    uc.TotalBounties,
    pa.ActivityRank,
    CASE 
        WHEN uc.TotalPosts > 5 THEN 'Frequent Contributor'
        WHEN COALESCE(ub.GoldBadges, 0) > 0 THEN 'Expert Contributor'
        ELSE 'Novice Contributor'
    END AS ContributorCategory
FROM UserContribution uc
LEFT JOIN UserBadges ub ON uc.UserId = ub.UserId
LEFT JOIN PostsActivity pa ON uc.UserId = pa.OwnerUserId
WHERE uc.TotalPosts > 0
ORDER BY uc.TotalPosts DESC, uc.DisplayName ASC;

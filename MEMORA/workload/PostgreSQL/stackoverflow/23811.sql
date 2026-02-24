WITH UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS TotalBadges,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(p.Score) AS AvgScore,
        MAX(p.ViewCount) AS MaxViews
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
SuspiciousUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        COALESCE(ub.TotalBadges, 0) AS TotalBadges,
        ps.TotalPosts,
        ps.TotalQuestions,
        ps.TotalAnswers,
        CASE 
            WHEN ps.TotalAnswers > ps.TotalQuestions * 2 THEN 'Overconfident'
            WHEN ps.TotalQuestions = 0 THEN 'Postless'
            ELSE 'Normal' 
        END AS UserStatus
    FROM 
        Users u
    LEFT JOIN 
        UserBadgeCounts ub ON u.Id = ub.UserId
    LEFT JOIN 
        PostStats ps ON u.Id = ps.OwnerUserId
)
SELECT 
    su.Id,
    su.DisplayName,
    su.Reputation,
    su.TotalBadges,
    su.TotalPosts,
    su.TotalQuestions,
    su.TotalAnswers,
    su.UserStatus,
    CASE 
        WHEN su.UserStatus = 'Overconfident' THEN 'Review Needed'
        WHEN su.UserStatus = 'Postless' THEN 'Engagement Suggested'
        ELSE 'Regular User'
    END AS Recommendation,
    (
        SELECT STRING_AGG(DISTINCT pt.Name, ', ') 
        FROM PostHistory ph
        JOIN PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
        WHERE ph.UserId = su.Id
    ) AS ActivitySummary,
    (
        SELECT COUNT(*)
        FROM Comments c 
        WHERE c.UserId = su.Id
    ) AS TotalComments
FROM 
    SuspiciousUsers su
WHERE 
    su.Reputation < (
        SELECT AVG(Reputation) 
        FROM Users
    )
  AND su.TotalBadges > 0
  AND su.TotalPosts < 5
ORDER BY 
    su.Reputation DESC,
    su.TotalPosts ASC;


WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) FILTER (WHERE b.Class = 1) AS GoldBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 2) AS SilverBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 3) AS BronzeBadges,
        COUNT(b.Id) AS TotalBadges,
        SUM(CASE WHEN b.Date >= DATE '2024-10-01' - INTERVAL '1 year' THEN 1 ELSE 0 END) AS RecentBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(p.Score) AS AvgScore
    FROM Posts p
    GROUP BY p.OwnerUserId
),
RecentComments AS (
    SELECT 
        c.UserId,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT c.PostId) AS PostsCommented
    FROM Comments c
    WHERE c.CreationDate >= DATE '2024-10-01' - INTERVAL '30 days'
    GROUP BY c.UserId
)
SELECT 
    u.DisplayName,
    COALESCE(ub.GoldBadges, 0) AS GoldBadges,
    COALESCE(ub.SilverBadges, 0) AS SilverBadges,
    COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(ps.PostCount, 0) AS TotalPosts,
    COALESCE(ps.QuestionCount, 0) AS TotalQuestions,
    COALESCE(ps.AnswerCount, 0) AS TotalAnswers,
    COALESCE(ps.AvgScore, 0) AS AveragePostScore,
    COALESCE(rc.CommentCount, 0) AS RecentCommentCount,
    COALESCE(rc.PostsCommented, 0) AS RecentCommentedPosts,
    CASE 
        WHEN COALESCE(ub.RecentBadges, 0) > 0 THEN 'Active'
        ELSE 'Inactive' 
    END AS UserActivity
FROM Users u
LEFT JOIN UserBadges ub ON u.Id = ub.UserId
LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
LEFT JOIN RecentComments rc ON u.Id = rc.UserId
WHERE u.Reputation > 1000
ORDER BY u.DisplayName;

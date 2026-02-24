WITH UserBadgeStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
), 
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN p.ClosedDate IS NOT NULL THEN 1 ELSE 0 END) AS ClosedPosts
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
), 
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(ps.TotalPosts, 0) AS TotalPosts,
        COALESCE(ps.Questions, 0) AS Questions,
        COALESCE(ps.Answers, 0) AS Answers,
        COALESCE(ps.ClosedPosts, 0) AS ClosedPosts,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        PostStats ps ON u.Id = ps.OwnerUserId
    LEFT JOIN 
        UserBadgeStats ub ON u.Id = ub.UserId
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.TotalPosts,
    u.Questions,
    u.Answers,
    u.ClosedPosts,
    GREATEST(u.GoldBadges, u.SilverBadges, u.BronzeBadges) AS MaxBadges,
    CASE 
        WHEN u.TotalPosts = 0 THEN 'No Posts'
        WHEN u.ClosedPosts > 0 THEN 'Contains Closed Posts'
        ELSE 'Active Participant'
    END AS EngagementLevel,
    string_agg(pt.Name, ', ') AS PostTypes
FROM 
    UserPostStats u
LEFT JOIN 
    Posts p ON u.UserId = p.OwnerUserId
LEFT JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    u.UserId, u.DisplayName, u.TotalPosts, u.Questions, u.Answers, u.ClosedPosts, u.GoldBadges, u.SilverBadges, u.BronzeBadges
ORDER BY 
    u.TotalPosts DESC, u.DisplayName ASC;

WITH UserActivity AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation, 
        COUNT(DISTINCT p.Id) AS TotalPosts, 
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(v.BountyAmount) AS TotalBounty,
        SUM(CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3, 6, 12) 
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        u.Reputation > 1000 
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostStats AS (
    SELECT 
        p.PostTypeId,
        COUNT(*) AS PostCount,
        AVG(p.Score) AS AvgScore,
        AVG(p.ViewCount) AS AvgViewCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
    GROUP BY 
        p.PostTypeId
),
BadgeStats AS (
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
),
FinalStats AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.TotalPosts,
        ua.TotalAnswers,
        ua.TotalQuestions,
        ua.TotalBounty,
        ua.TotalComments,
        COALESCE(bs.TotalBadges, 0) AS TotalBadges,
        COALESCE(bs.GoldBadges, 0) AS GoldBadges,
        COALESCE(bs.SilverBadges, 0) AS SilverBadges,
        COALESCE(bs.BronzeBadges, 0) AS BronzeBadges,
        ps.PostCount,
        ps.AvgScore,
        ps.AvgViewCount
    FROM 
        UserActivity ua
    LEFT JOIN 
        BadgeStats bs ON ua.UserId = bs.UserId
    LEFT JOIN 
        (SELECT PostTypeId, SUM(PostCount) AS PostCount, AVG(AvgScore) AS AvgScore, AVG(AvgViewCount) AS AvgViewCount FROM PostStats GROUP BY PostTypeId) ps ON true
)
SELECT 
    * 
FROM 
    FinalStats
ORDER BY 
    TotalPosts DESC, TotalAnswers DESC, TotalBounty DESC
LIMIT 100;
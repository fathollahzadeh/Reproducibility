WITH UserBadgeStats AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
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
PostActivity AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN p.PostTypeId IN (4, 5) THEN 1 ELSE 0 END) AS TagWikis,
        AVG(p.Score) AS AvgScore
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    u.CreationDate,
    u.LastAccessDate,
    COALESCE(ubs.BadgeCount, 0) AS TotalBadges,
    COALESCE(ubs.GoldBadges, 0) AS GoldBadges,
    COALESCE(ubs.SilverBadges, 0) AS SilverBadges,
    COALESCE(ubs.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(pa.TotalPosts, 0) AS TotalPosts,
    COALESCE(pa.Questions, 0) AS TotalQuestions,
    COALESCE(pa.Answers, 0) AS TotalAnswers,
    COALESCE(pa.TagWikis, 0) AS TotalTagWikis,
    COALESCE(pa.AvgScore, 0) AS AvgPostScore
FROM 
    Users u
LEFT JOIN 
    UserBadgeStats ubs ON u.Id = ubs.UserId
LEFT JOIN 
    PostActivity pa ON u.Id = pa.OwnerUserId
WHERE 
    u.Reputation > 1000
ORDER BY 
    u.Reputation DESC, u.DisplayName;

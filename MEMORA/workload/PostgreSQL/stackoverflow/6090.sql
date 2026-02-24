
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(p.Id) AS TotalPosts, 
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(p.Score) AS TotalScore,
        SUM(COALESCE(v.Count, 0)) AS TotalVotes
    FROM 
        Users u 
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId 
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS Count FROM Votes GROUP BY PostId) v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
), BadgeStats AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS TotalBadges,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS TotalGoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS TotalSilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS TotalBronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    ups.UserId, 
    ups.DisplayName, 
    ups.TotalPosts, 
    ups.TotalQuestions, 
    ups.TotalAnswers, 
    ups.TotalScore,
    ups.TotalVotes,
    COALESCE(bs.TotalBadges, 0) AS TotalBadges,
    COALESCE(bs.TotalGoldBadges, 0) AS TotalGoldBadges,
    COALESCE(bs.TotalSilverBadges, 0) AS TotalSilverBadges,
    COALESCE(bs.TotalBronzeBadges, 0) AS TotalBronzeBadges
FROM 
    UserPostStats ups
LEFT JOIN 
    BadgeStats bs ON ups.UserId = bs.UserId
ORDER BY 
    ups.TotalScore DESC, 
    ups.TotalPosts DESC 
LIMIT 100;

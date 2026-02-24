WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT 
    u.DisplayName,
    ups.TotalPosts,
    ups.Questions,
    ups.Answers,
    ups.TotalViews,
    ups.TotalScore,
    (SELECT COUNT(*) FROM Votes v WHERE v.UserId = ups.UserId) AS TotalVotes,
    (SELECT COUNT(*) FROM Comments c WHERE c.UserId = ups.UserId) AS TotalComments,
    (SELECT COUNT(*) FROM Badges b WHERE b.UserId = ups.UserId) AS TotalBadges
FROM 
    UserPostStats ups
JOIN 
    Users u ON ups.UserId = u.Id
ORDER BY 
    ups.TotalScore DESC
LIMIT 100;

WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN p.ViewCount > 100 THEN 1 ELSE 0 END) AS PopularPosts,
        SUM(COALESCE(c.CommentCount, 0)) AS TotalComments,
        SUM(COALESCE(b.Count, 0)) AS TotalBadges,
        RANK() OVER (ORDER BY COUNT(p.Id) DESC) AS PostRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT UserId, COUNT(*) AS Count FROM Badges GROUP BY UserId) b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id, u.DisplayName
), PopularUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        Questions,
        Answers,
        PopularPosts,
        TotalComments,
        TotalBadges,
        PostRank
    FROM 
        UserActivity
    WHERE 
        PostRank <= 10
)
SELECT 
    pu.DisplayName,
    pu.TotalPosts,
    pu.Questions,
    pu.Answers,
    pu.PopularPosts,
    pu.TotalComments,
    pu.TotalBadges,
    (SELECT AVG(TotalPosts) FROM UserActivity) AS AvgPosts,
    (SELECT MAX(ViewCount) FROM Posts) AS MaxViewCount
FROM 
    PopularUsers pu
ORDER BY 
    pu.TotalPosts DESC;

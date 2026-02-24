WITH UserPostStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId IN (4, 5) THEN 1 ELSE 0 END) AS TotalTagWikis,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AvgViewCount,
        COUNT(CASE WHEN b.Id IS NOT NULL THEN 1 END) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostEngagement AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS TotalComments,
        COUNT(v.Id) AS TotalVotes,
        p.CreationDate,
        p.LastActivityDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.CreationDate, p.LastActivityDate
)

SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.TotalPosts,
    ups.TotalQuestions,
    ups.TotalAnswers,
    ups.TotalTagWikis,
    ups.TotalScore,
    ups.AvgViewCount,
    ups.TotalBadges,
    pe.PostId,
    pe.TotalComments,
    pe.TotalVotes,
    pe.CreationDate,
    pe.LastActivityDate
FROM 
    UserPostStatistics ups
JOIN 
    PostEngagement pe ON ups.UserId = pe.PostId
ORDER BY 
    ups.TotalScore DESC, ups.TotalPosts DESC;
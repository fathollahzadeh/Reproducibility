WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS TotalPosts,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS TotalQuestions,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS TotalAnswers,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
PostActivityStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS TotalComments,
        COUNT(v.Id) AS TotalVotes,
        COUNT(DISTINCT h.UserId) AS TotalEdits
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory h ON p.Id = h.PostId
    GROUP BY 
        p.Id
)

SELECT 
    ups.UserId,
    ups.TotalPosts,
    ups.TotalQuestions,
    ups.TotalAnswers,
    ups.TotalScore,
    pas.TotalComments,
    pas.TotalVotes,
    pas.TotalEdits
FROM 
    UserPostStats ups
LEFT JOIN 
    PostActivityStats pas ON ups.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = pas.PostId LIMIT 1)
ORDER BY 
    ups.TotalPosts DESC, ups.TotalScore DESC;
WITH PostCounts AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS TotalPosts
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
),
UserActivity AS (
    SELECT 
        u.DisplayName,
        COUNT(p.Id) AS PostsCreated,
        SUM(CASE 
            WHEN p.PostTypeId = 1 THEN 1 
            ELSE 0 
        END) AS QuestionsCreated,
        SUM(CASE 
            WHEN p.PostTypeId = 2 THEN 1 
            ELSE 0 
        END) AS AnswersCreated,
        MAX(p.CreationDate) AS LastActivityDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.DisplayName
)
SELECT 
    pc.PostType,
    pc.TotalPosts,
    ua.DisplayName,
    ua.PostsCreated,
    ua.QuestionsCreated,
    ua.AnswersCreated,
    ua.LastActivityDate
FROM 
    PostCounts pc
JOIN 
    UserActivity ua ON ua.PostsCreated > 0
ORDER BY 
    pc.TotalPosts DESC, ua.PostsCreated DESC;
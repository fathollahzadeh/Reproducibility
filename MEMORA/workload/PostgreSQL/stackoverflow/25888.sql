
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT a.Id) AS TotalAnswers,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        COUNT(DISTINCT c.Id) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId 
    LEFT JOIN 
        Comments c ON p.Id = c.PostId 
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
TopTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY 
        t.TagName
    ORDER BY 
        PostCount DESC
    LIMIT 10
),
UserTagActivity AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        tt.TagName
    FROM 
        UserActivity ua
    JOIN 
        Posts p ON ua.UserId = p.OwnerUserId
    JOIN 
        TopTags tt ON p.Tags LIKE CONCAT('%', tt.TagName, '%')
)
SELECT 
    uta.DisplayName,
    uta.TagName,
    ua.TotalPosts,
    ua.TotalAnswers,
    ua.TotalUpvotes,
    ua.TotalDownvotes,
    ua.TotalComments
FROM 
    UserActivity ua
JOIN 
    UserTagActivity uta ON ua.UserId = uta.UserId
ORDER BY 
    ua.TotalUpvotes DESC, ua.TotalPosts DESC;

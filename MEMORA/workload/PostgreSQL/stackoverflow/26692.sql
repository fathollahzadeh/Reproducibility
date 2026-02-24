WITH RankedUserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(p.ViewCount) AS TotalViews,
        RANK() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 0
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        TotalPosts,
        TotalAnswers,
        TotalQuestions,
        TotalViews
    FROM 
        RankedUserActivity
    WHERE 
        UserRank <= 10
),
PostTags AS (
    SELECT 
        DISTINCT p.Id AS PostId, 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS Tag
    FROM 
        Posts p
    WHERE 
        p.Tags IS NOT NULL AND p.Tags <> ''
),
TagActivity AS (
    SELECT 
        t.Tag, 
        COUNT(DISTINCT p.Id) AS PostsWithTag,
        SUM(COALESCE(c.CommentCount, 0)) AS TotalComments
    FROM 
        PostTags t
    JOIN 
        Posts p ON t.PostId = p.Id
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) c ON p.Id = c.PostId
    GROUP BY 
        t.Tag
    ORDER BY 
        PostsWithTag DESC
    LIMIT 5
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.TotalAnswers,
    tu.TotalQuestions,
    tu.TotalViews,
    ta.Tag,
    ta.PostsWithTag,
    ta.TotalComments
FROM 
    TopUsers tu
JOIN 
    TagActivity ta ON true 
ORDER BY 
    tu.UserId, ta.PostsWithTag DESC;
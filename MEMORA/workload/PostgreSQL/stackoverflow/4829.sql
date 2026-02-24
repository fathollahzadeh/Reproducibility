
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(u.Reputation) OVER (PARTITION BY u.Id) AS AvgReputation,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
QuestionStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS QuestionsAsked,
        AVG(p.ViewCount) AS AvgViews,
        COUNT(c.Id) AS TotalComments
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.OwnerUserId
),
PopularTags AS (
    SELECT 
        unnest(string_to_array(p.Tags, '><')) AS Tag,
        COUNT(p.Id) AS TagCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        unnest(string_to_array(p.Tags, '><'))
    HAVING 
        COUNT(p.Id) > 10
)
SELECT 
    us.DisplayName,
    us.TotalPosts,
    us.TotalQuestions,
    us.TotalAnswers,
    us.AvgReputation,
    qs.QuestionsAsked,
    qs.AvgViews,
    qs.TotalComments,
    pt.Tag AS PopularTag,
    pt.TagCount
FROM 
    UserStats us
LEFT JOIN 
    QuestionStats qs ON us.UserId = qs.OwnerUserId
LEFT JOIN 
    PopularTags pt ON pt.Tag IN (
        SELECT 
            unnest(string_to_array(p.Tags, '><')) 
        FROM 
            Posts p 
        WHERE 
            p.OwnerUserId = us.UserId
    )
WHERE 
    us.TotalPosts > 5
ORDER BY 
    us.AvgReputation DESC
LIMIT 50;

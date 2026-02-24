
WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        AVG(p.ViewCount) AS AverageViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
ActiveUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.PostCount,
        us.QuestionCount,
        us.AnswerCount,
        us.Upvotes,
        us.Downvotes,
        us.AverageViews,
        ROW_NUMBER() OVER (ORDER BY us.PostCount DESC) AS Rank
    FROM 
        UserStatistics us
    WHERE 
        us.PostCount >= 10
),
TopUsers AS (
    SELECT
        au.UserId,
        au.DisplayName,
        au.PostCount,
        au.QuestionCount,
        au.AnswerCount,
        au.Upvotes,
        au.Downvotes,
        au.AverageViews
    FROM 
        ActiveUsers au
    WHERE 
        au.Rank <= 10
)
SELECT 
    tu.DisplayName AS TopUser,
    tu.PostCount AS TotalPosts,
    tu.QuestionCount AS TotalQuestions,
    tu.AnswerCount AS TotalAnswers,
    tu.Upvotes AS TotalUpvotes,
    tu.Downvotes AS TotalDownvotes,
    tu.AverageViews AS AvgPostViews,
    STRING_AGG(DISTINCT p.Title, ', ') AS PostTitles,
    STRING_AGG(DISTINCT t.TagName, ', ') AS AssociatedTags
FROM 
    TopUsers tu
LEFT JOIN 
    Posts p ON tu.UserId = p.OwnerUserId
LEFT JOIN 
    UNNEST(REGEXP_SPLIT_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '>, *')) AS tag_list ON TRUE
LEFT JOIN 
    Tags t ON tag_list = t.TagName
GROUP BY 
    tu.UserId, tu.DisplayName, tu.PostCount, tu.QuestionCount, tu.AnswerCount, tu.Upvotes, tu.Downvotes, tu.AverageViews
ORDER BY 
    tu.Upvotes DESC;

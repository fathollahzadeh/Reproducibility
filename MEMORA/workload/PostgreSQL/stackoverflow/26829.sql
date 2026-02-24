WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
TagStats AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(p.Id) AS PostsWithTag,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.AnswerCount) AS TotalAnswers
    FROM Tags t
    JOIN Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')
    GROUP BY t.Id, t.TagName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        Questions,
        Answers,
        TotalViews,
        TotalScore,
        ROW_NUMBER() OVER (ORDER BY TotalScore DESC) AS Rank
    FROM UserPostStats
    WHERE TotalPosts > 0
),
TopTags AS (
    SELECT 
        TagId,
        TagName,
        PostsWithTag,
        TotalViews,
        TotalAnswers,
        ROW_NUMBER() OVER (ORDER BY TotalViews DESC) AS Rank
    FROM TagStats
    WHERE PostsWithTag > 0
)
SELECT 
    tu.Rank AS UserRank,
    tu.DisplayName AS TopUser,
    tu.TotalPosts,
    tu.Questions,
    tu.Answers,
    tu.TotalViews AS UserTotalViews,
    tu.TotalScore AS UserTotalScore,
    tt.Rank AS TagRank,
    tt.TagName AS TopTag,
    tt.PostsWithTag,
    tt.TotalViews AS TagTotalViews,
    tt.TotalAnswers AS TagTotalAnswers
FROM TopUsers tu
JOIN TopTags tt ON tu.TotalViews > 1000 AND tt.TotalViews > 1000
WHERE tu.Rank <= 10 AND tt.Rank <= 10
ORDER BY tu.Rank, tt.Rank;

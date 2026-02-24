WITH TagCounts AS (
    SELECT 
        Tags.TagName,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(Posts.ViewCount) AS TotalViews,
        AVG(Posts.Score) AS AverageScore
    FROM 
        Tags
    JOIN 
        Posts ON Tags.Id = Posts.Id
    WHERE 
        Posts.PostTypeId = 1 
    GROUP BY 
        Tags.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalViews,
        AverageScore,
        RANK() OVER (ORDER BY PostCount DESC) AS RankByPostCount,
        RANK() OVER (ORDER BY TotalViews DESC) AS RankByTotalViews,
        RANK() OVER (ORDER BY AverageScore DESC) AS RankByAverageScore
    FROM 
        TagCounts
),
UserActivity AS (
    SELECT 
        Users.DisplayName,
        COUNT(DISTINCT Posts.Id) AS QuestionsAsked,
        SUM(Posts.ViewCount) AS TotalViews,
        SUM(Posts.AnswerCount) AS TotalAnswers
    FROM 
        Users
    JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    WHERE 
        Posts.PostTypeId = 1 
    GROUP BY 
        Users.DisplayName
),
TopUsers AS (
    SELECT 
        DisplayName,
        QuestionsAsked,
        TotalViews,
        TotalAnswers,
        RANK() OVER (ORDER BY QuestionsAsked DESC) AS RankByQuestionsAsked,
        RANK() OVER (ORDER BY TotalViews DESC) AS RankByTotalViews,
        RANK() OVER (ORDER BY TotalAnswers DESC) AS RankByTotalAnswers
    FROM 
        UserActivity
)
SELECT 
    t.TagName, 
    t.PostCount, 
    t.TotalViews, 
    t.AverageScore,
    u.DisplayName as TopUser, 
    u.QuestionsAsked, 
    u.TotalViews as UserTotalViews, 
    u.TotalAnswers
FROM 
    TopTags t
JOIN 
    TopUsers u ON u.TotalViews = (SELECT MAX(TotalViews) FROM TopUsers WHERE TotalViews >= u.TotalViews)
WHERE 
    t.RankByPostCount <= 5 AND u.RankByQuestionsAsked <= 5
ORDER BY 
    t.RankByPostCount, u.RankByQuestionsAsked;
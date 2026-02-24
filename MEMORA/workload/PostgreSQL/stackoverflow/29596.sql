
WITH TagStatistics AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AverageScore
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY 
        T.TagName
),

UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(COALESCE(B.Class, 0)) AS TotalBadges,
        SUM(U.Reputation) AS TotalReputation,
        COUNT(DISTINCT P.Id) AS PostsCreated
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON B.UserId = U.Id
    LEFT JOIN 
        Posts P ON P.OwnerUserId = U.Id
    GROUP BY 
        U.Id, U.DisplayName
),

TopTags AS (
    SELECT 
        TagName,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalViews,
        AverageScore,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagStatistics
),

TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalBadges,
        TotalReputation,
        PostsCreated,
        ROW_NUMBER() OVER (ORDER BY TotalReputation DESC) AS Rank
    FROM 
        UserReputation
)

SELECT 
    T.TagName,
    T.PostCount,
    T.QuestionCount,
    T.AnswerCount,
    T.TotalViews,
    T.AverageScore,
    U.DisplayName AS TopUser,
    U.TotalReputation
FROM 
    TopTags T
JOIN 
    TopUsers U ON U.PostsCreated > 0
WHERE 
    T.Rank <= 10 AND U.Rank <= 10
ORDER BY 
    T.PostCount DESC, U.TotalReputation DESC;

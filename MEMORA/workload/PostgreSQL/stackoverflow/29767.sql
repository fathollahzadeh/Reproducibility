
WITH TagStats AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.AnswerCount) AS TotalAnswers,
        SUM(P.CommentCount) AS TotalComments
    FROM Tags T
    LEFT JOIN Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    WHERE T.Count > 0
    GROUP BY T.TagName
),
HighEngagementTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalViews,
        TotalAnswers,
        TotalComments,
        (TotalViews + TotalAnswers * 2 + TotalComments * 0.5) AS EngagementScore
    FROM TagStats
    WHERE PostCount > 5
),
TopTags AS (
    SELECT 
        TagName,
        EngagementScore,
        ROW_NUMBER() OVER (ORDER BY EngagementScore DESC) AS Rank
    FROM HighEngagementTags
)
SELECT 
    T.TagName,
    T.EngagementScore,
    P.Id AS PostId,
    P.Title,
    P.CreationDate,
    U.DisplayName AS OwnerDisplayName,
    U.Reputation AS OwnerReputation,
    COUNT(C.Id) AS CommentCount
FROM TopTags T
JOIN Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
JOIN Users U ON P.OwnerUserId = U.Id
LEFT JOIN Comments C ON P.Id = C.PostId
WHERE T.Rank <= 10
GROUP BY T.TagName, T.EngagementScore, P.Id, P.Title, P.CreationDate, U.DisplayName, U.Reputation
ORDER BY T.EngagementScore DESC, P.ViewCount DESC;

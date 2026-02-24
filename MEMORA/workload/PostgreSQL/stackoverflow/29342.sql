
WITH TagStats AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        AVG(COALESCE(P.ANSWERCOUNT, 0)) AS AvgAnswerCount,
        ARRAY_AGG(DISTINCT U.DisplayName) AS ContributingUsers
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    LEFT JOIN 
        Users U ON U.Id = P.OwnerUserId
    GROUP BY 
        T.TagName
),
MostActiveTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalViews,
        TotalScore,
        AvgAnswerCount,
        ContributingUsers
    FROM 
        TagStats
    WHERE 
        PostCount > 10
    ORDER BY 
        TotalScore DESC
    FETCH FIRST 5 ROWS ONLY
),
UserStats AS (
    SELECT 
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS QuestionsAnswered,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvotesReceived,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvotesReceived
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON P.OwnerUserId = U.Id AND P.PostTypeId = 2 
    LEFT JOIN 
        Votes V ON V.PostId = P.Id
    GROUP BY 
        U.DisplayName
    ORDER BY 
        QuestionsAnswered DESC
    FETCH FIRST 10 ROWS ONLY
)
SELECT 
    M.TagName,
    M.PostCount,
    M.TotalViews,
    M.TotalScore,
    M.AvgAnswerCount,
    M.ContributingUsers,
    U.DisplayName AS TopUser,
    U.QuestionsAnswered,
    U.UpvotesReceived,
    U.DownvotesReceived
FROM 
    MostActiveTags M
JOIN 
    UserStats U ON U.QuestionsAnswered > 5 
ORDER BY 
    M.TotalScore DESC, U.UpvotesReceived DESC;

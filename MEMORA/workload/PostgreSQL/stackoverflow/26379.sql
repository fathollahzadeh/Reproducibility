WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName AS UserDisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(P.Score) AS AvgPostScore,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        U.Reputation > 100
    GROUP BY 
        U.Id, U.DisplayName
),
PostTagStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        STRING_AGG(T.TagName, ', ') AS Tags,
        COALESCE(PH.CreationDate, P.CreationDate) AS LastActivity,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(V.Id) AS VoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Tags T ON POSITION(T.TagName IN P.Tags) > 0
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        P.Id, P.Title, P.CreationDate, PH.CreationDate
),
BenchmarkResults AS (
    SELECT 
        U.UserId,
        U.UserDisplayName,
        U.TotalPosts,
        U.TotalQuestions,
        U.TotalAnswers,
        U.AvgPostScore,
        P.Tags,
        P.CommentCount,
        P.VoteCount
    FROM 
        UserPostStats U
    JOIN 
        PostTagStats P ON U.TotalQuestions > 0
    ORDER BY 
        U.TotalPosts DESC, U.TotalQuestions DESC
)
SELECT 
    UserDisplayName,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    AvgPostScore,
    Tags,
    CommentCount,
    VoteCount
FROM 
    BenchmarkResults
WHERE 
    TotalPosts > 10
LIMIT 20;
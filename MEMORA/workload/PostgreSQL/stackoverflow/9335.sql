WITH UserReputation AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation, 
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TagStatistics AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AverageScore
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.TagName
),
PostHistorySummary AS (
    SELECT 
        P.Id AS PostId,
        PH.PostHistoryTypeId,
        COUNT(PH.Id) AS HistoryCount
    FROM 
        Posts P
    JOIN 
        PostHistory PH ON P.Id = PH.PostId
    GROUP BY 
        P.Id, PH.PostHistoryTypeId
)
SELECT 
    U.DisplayName AS UserName,
    U.Reputation AS UserReputation,
    U.TotalPosts,
    U.QuestionCount,
    U.AnswerCount,
    T.TagName,
    T.PostCount,
    T.TotalViews,
    T.AverageScore,
    PHS.PostId,
    PHS.PostHistoryTypeId,
    PHS.HistoryCount
FROM 
    UserReputation U
JOIN 
    TagStatistics T ON U.TotalPosts > 0
JOIN 
    PostHistorySummary PHS ON U.UserId = PHS.PostId
WHERE 
    U.Reputation > 1000 
ORDER BY 
    U.Reputation DESC, 
    T.PostCount DESC, 
    PHS.HistoryCount DESC
LIMIT 100;

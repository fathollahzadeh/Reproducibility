
WITH UserActivity AS (
    SELECT 
        US.Id AS UserId,
        US.DisplayName,
        COUNT(CASE WHEN V.VoteTypeId IN (2, 3) THEN 1 END) AS VoteCount,
        SUM(COALESCE(P.Score, 0)) AS TotalPostScore,
        SUM(COALESCE(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END, 0)) AS QuestionCount,
        SUM(COALESCE(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END, 0)) AS AnswerCount
    FROM 
        Users US
    LEFT JOIN 
        Posts P ON US.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        US.Id, US.DisplayName
),
PostStatistics AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        US.DisplayName AS OwnerName,
        P.Score,
        P.ViewCount,
        DENSE_RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS ScoreRank,
        DENSE_RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.ViewCount DESC) AS ViewRank
    FROM 
        Posts P
    JOIN 
        Users US ON P.OwnerUserId = US.Id
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 YEAR'
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        CRT.Name AS CloseReason
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes CRT ON CAST(PH.Comment AS INTEGER) = CRT.Id
    WHERE 
        PH.PostHistoryTypeId = 10
),
CombinedStats AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.VoteCount,
        UA.TotalPostScore,
        UA.QuestionCount,
        UA.AnswerCount,
        PS.PostId,
        PS.Title,
        PS.CreationDate,
        PS.Score,
        PS.ViewCount,
        CASE 
            WHEN PS.ScoreRank <= 10 THEN 'Top 10 by Score'
            ELSE 'Others'
        END AS ScoreCategory,
        CASE 
            WHEN PS.ViewRank <= 10 THEN 'Top 10 by Views'
            ELSE 'Others'
        END AS ViewCategory,
        COALESCE(CP.CloseReason, 'Not Closed') AS PostCloseReason
    FROM 
        UserActivity UA
    LEFT JOIN 
        PostStatistics PS ON UA.DisplayName = PS.OwnerName
    LEFT JOIN 
        ClosedPosts CP ON PS.PostId = CP.PostId
)
SELECT 
    UserId,
    DisplayName,
    VoteCount,
    TotalPostScore,
    QuestionCount,
    AnswerCount,
    PostId,
    Title,
    CreationDate,
    Score,
    ViewCount,
    ScoreCategory,
    ViewCategory,
    PostCloseReason
FROM 
    CombinedStats
WHERE 
    TotalPostScore > 50 
    AND (QuestionCount > 5 OR AnswerCount > 10)
ORDER BY 
    TotalPostScore DESC,
    CreationDate DESC;

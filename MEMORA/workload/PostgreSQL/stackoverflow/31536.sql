WITH RecentPostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        P.Score,
        P.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY U.Location ORDER BY P.CreationDate DESC) AS RecentRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1 
        AND P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
AnswerStatistics AS (
    SELECT 
        P.Id AS QuestionId,
        COUNT(A.Id) AS TotalAnswers,
        AVG(A.Score) AS AvgAnswerScore
    FROM 
        Posts P
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        P.Id
),
HighScoreQuestions AS (
    SELECT 
        R.PostId,
        R.Title,
        R.OwnerDisplayName,
        R.CreationDate,
        R.Score,
        A.TotalAnswers,
        A.AvgAnswerScore
    FROM 
        RecentPostStats R
    JOIN 
        AnswerStatistics A ON R.PostId = A.QuestionId
    WHERE 
        R.Score > (SELECT AVG(Score) FROM Posts WHERE PostTypeId = 1) 
),
ClosedPosts AS (
    SELECT 
        P.Id AS ClosedPostId,
        P.Title,
        PH.CreationDate AS ClosedDate,
        PH.Comment AS CloseReason
    FROM 
        Posts P
    JOIN 
        PostHistory PH ON P.Id = PH.PostId
    WHERE 
        PH.PostHistoryTypeId = 10 
)
SELECT 
    Q.Title AS QuestionTitle,
    Q.OwnerDisplayName,
    Q.CreationDate AS QuestionDate,
    Q.Score AS QuestionScore,
    Q.TotalAnswers,
    Q.AvgAnswerScore,
    C.ClosedPostId,
    C.ClosedDate,
    COALESCE(C.CloseReason, 'Not Closed') AS CloseReason
FROM 
    HighScoreQuestions Q
LEFT JOIN 
    ClosedPosts C ON Q.PostId = C.ClosedPostId
WHERE 
    (C.ClosedPostId IS NULL OR C.ClosedDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '7 days')
ORDER BY 
    Q.Score DESC,
    Q.CreationDate ASC;
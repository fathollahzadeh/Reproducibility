WITH RankedUserPosts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS NumberOfPosts,
        AVG(P.Score) AS AveragePostScore,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        SUM(CASE WHEN P.PostTypeId IN (10, 11) THEN 1 ELSE 0 END) AS CloseReopenedCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN P.ViewCount ELSE 0 END) AS TotalViewCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostHistoryAggregation AS (
    SELECT 
        PH.UserId,
        PH.PostId,
        PH.PostHistoryTypeId,
        COUNT(*) AS RevisionCount,
        STRING_AGG(DISTINCT PH.Comment, '; ') AS Comments
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (10, 11, 12, 13)
    GROUP BY 
        PH.UserId, PH.PostId, PH.PostHistoryTypeId
),
FinalBenchmarkingResult AS (
    SELECT 
        R.DisplayName,
        R.NumberOfPosts,
        R.AveragePostScore,
        R.QuestionsCount,
        R.AnswersCount,
        R.CloseReopenedCount,
        R.TotalViewCount,
        COALESCE(PH.RevisionCount, 0) AS TotalPostRevisions,
        COALESCE(PH.Comments, 'No Comments') AS RevisionComments
    FROM 
        RankedUserPosts R
    LEFT JOIN 
        PostHistoryAggregation PH ON R.UserId = PH.UserId 
    ORDER BY 
        R.NumberOfPosts DESC, R.AveragePostScore DESC
)
SELECT 
    *
FROM 
    FinalBenchmarkingResult
WHERE 
    TotalPostRevisions > 0
OR 
    QuestionsCount > 0
OR 
    AnswersCount > 0;

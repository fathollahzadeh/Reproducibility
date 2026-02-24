WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalAnswers,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS TotalQuestions,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBountyEarned,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS Rank
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9) 
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
QuestionStats AS (
    SELECT 
        P.Id AS QuestionId,
        P.Title,
        COUNT(A.Id) AS AnswerCount,
        AVG(COALESCE(CAST(A.Score AS FLOAT), 0)) AS AvgAnswerScore,
        COUNT(DISTINCT C.Id) AS TotalComments,
        MAX(P.LastActivityDate) AS LastActiveDate,
        CASE
            WHEN MAX(P.ClosedDate) IS NOT NULL THEN 'Closed'
            ELSE 'Open'
        END AS Status
    FROM Posts P
    LEFT JOIN Posts A ON P.Id = A.ParentId AND A.PostTypeId = 2 
    LEFT JOIN Comments C ON P.Id = C.PostId
    WHERE P.PostTypeId = 1 
    GROUP BY P.Id, P.Title
),
PostHistoryData AS (
    SELECT 
        PH.PostId,
        DENSE_RANK() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS RevisionRank,
        PH.PostHistoryTypeId,
        PH.CreationDate,
        COALESCE(PH.Comment, 'No comment') AS Comment
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId IN (6, 10, 14) 
)
SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.Reputation,
    UA.TotalPosts,
    UA.TotalQuestions,
    UA.TotalAnswers,
    UA.TotalBountyEarned,
    Q.questionId,
    Q.Title AS QuestionTitle,
    Q.AnswerCount,
    Q.AvgAnswerScore,
    Q.TotalComments,
    PH.RevisionRank,
    PH.PostHistoryTypeId,
    PH.CreationDate AS HistoryDate,
    PH.Comment,
    CASE 
        WHEN (UA.TotalPosts > 100 AND UA.Reputation >= 1000) THEN 'Veteran'
        ELSE 'Regular'
    END AS UserType,
    CASE
        WHEN Q.Status = 'Closed' THEN 'This question is closed, cannot accept new answers.'
        ELSE 'Open for answers.'
    END AS StatusMessage
FROM UserActivity UA
JOIN QuestionStats Q ON UA.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = Q.QuestionId)
LEFT JOIN PostHistoryData PH ON Q.QuestionId = PH.PostId AND PH.RevisionRank = 1
WHERE UA.Reputation > 0 AND UA.Reputation IS NOT NULL
ORDER BY UA.Reputation DESC, Q.AvgAnswerScore DESC;
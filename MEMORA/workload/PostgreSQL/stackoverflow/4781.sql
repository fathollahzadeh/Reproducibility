
WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.Score < 0 THEN 1 ELSE 0 END) AS NegativeScorePosts
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName
), 
PostVoteCounts AS (
    SELECT 
        P.Id AS PostId,
        COUNT(V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.Id
), 
ClosedPostInfo AS (
    SELECT 
        PH.PostId,
        MAX(PH.CreationDate) AS LastClosedDate,
        STRING_AGG(DISTINCT CTR.Name, ', ') AS CloseReasonNames
    FROM PostHistory PH
    INNER JOIN CloseReasonTypes CTR ON PH.Comment = CAST(CTR.Id AS VARCHAR)
    WHERE PH.PostHistoryTypeId = 10
    GROUP BY PH.PostId
)
SELECT 
    U.DisplayName,
    UPS.TotalPosts,
    UPS.QuestionCount,
    UPS.AnswerCount,
    UPS.NegativeScorePosts,
    P.Id AS PostId,
    P.Title,
    PVC.VoteCount,
    PVC.UpVotes,
    PVC.DownVotes,
    CPI.LastClosedDate,
    CPI.CloseReasonNames
FROM UserPostStats UPS
JOIN Users U ON UPS.UserId = U.Id
LEFT JOIN Posts P ON U.Id = P.OwnerUserId
LEFT JOIN PostVoteCounts PVC ON P.Id = PVC.PostId
LEFT JOIN ClosedPostInfo CPI ON P.Id = CPI.PostId
WHERE (UPS.QuestionCount > 0 OR UPS.AnswerCount > 0)
AND (CPI.LastClosedDate IS NULL OR CPI.LastClosedDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
ORDER BY UPS.TotalPosts DESC, PVC.UpVotes DESC
LIMIT 100;

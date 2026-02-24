
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        MAX(B.Date) AS LastBadgeDate,
        RANK() OVER (PARTITION BY U.Id ORDER BY COUNT(DISTINCT P.Id) DESC) AS ActivityRank
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Badges B ON U.Id = B.UserId
    WHERE U.Reputation > 1000
    GROUP BY U.Id, U.DisplayName
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        COALESCE(COUNT(C.ID), 0) AS CommentCount,
        COALESCE(AVG(V.BountyAmount), 0) AS AvgBounty 
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9) 
    WHERE P.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 YEAR'
    GROUP BY P.Id, P.Title, P.CreationDate, P.ViewCount
),
ClosedPostHistory AS (
    SELECT 
        PH.PostId,
        COUNT(*) AS CloseCount,
        STRING_AGG(DISTINCT C.Name, ', ') AS CloseReasons
    FROM PostHistory PH
    JOIN CloseReasonTypes C ON (PH.Comment::jsonb)::text::int = C.Id
    WHERE PH.PostHistoryTypeId IN (10, 11) 
    GROUP BY PH.PostId
),
AggregatedResults AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.PostCount,
        UA.QuestionCount,
        UA.AnswerCount,
        UA.UpVoteCount,
        UA.DownVoteCount,
        PS.PostId,
        PS.Title,
        PS.CreationDate,
        PS.ViewCount,
        PS.CommentCount,
        PS.AvgBounty,
        COALESCE(CPH.CloseCount, 0) AS CloseCount,
        COALESCE(CPH.CloseReasons, 'No Close Reasons') AS CloseReasons
    FROM UserActivity UA
    LEFT JOIN PostStatistics PS ON UA.QuestionCount > 0
    LEFT JOIN ClosedPostHistory CPH ON PS.PostId = CPH.PostId
)
SELECT 
    AR.UserId,
    AR.DisplayName,
    AR.PostCount,
    AR.QuestionCount,
    AR.AnswerCount,
    AR.UpVoteCount,
    AR.DownVoteCount,
    AR.Title,
    AR.CreationDate,
    AR.ViewCount,
    AR.CommentCount,
    AR.AvgBounty,
    AR.CloseCount,
    AR.CloseReasons
FROM AggregatedResults AR
WHERE AR.CloseCount > 0 
ORDER BY AR.UpVoteCount DESC, AR.PostCount DESC;

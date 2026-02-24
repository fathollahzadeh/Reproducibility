
WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounty,
        COUNT(DISTINCT P.Id) FILTER (WHERE P.PostTypeId = 1) AS QuestionCount,
        COUNT(DISTINCT P.Id) FILTER (WHERE P.PostTypeId = 2) AS AnswerCount
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Posts P ON V.PostId = P.Id
    GROUP BY U.Id, U.DisplayName
),
RecentPostActivity AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RecentRank,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    WHERE P.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days')
    GROUP BY P.Id, P.Title, P.OwnerUserId
),
PostCloseReasons AS (
    SELECT 
        PH.PostId,
        STRING_AGG(CRT.Name, ', ' ORDER BY CRT.Id) AS CloseReasonNames,
        COUNT(*) AS CloseCount
    FROM PostHistory PH
    JOIN CloseReasonTypes CRT ON CAST(PH.Comment AS INTEGER) = CRT.Id
    WHERE PH.PostHistoryTypeId = 10
    GROUP BY PH.PostId
),
MostActiveUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        RANK() OVER (ORDER BY SUM(UV.TotalBounty) DESC) AS UserRank,
        SUM(UV.UpVotes - UV.DownVotes) AS NetVotes
    FROM UserVoteStats UV
    JOIN Users U ON U.Id = UV.UserId
    GROUP BY U.Id, U.DisplayName
    HAVING SUM(UV.UpVotes - UV.DownVotes) > 0
)
SELECT 
    U.DisplayName AS User,
    U.Reputation AS UserReputation,
    RPA.Title AS RecentPostTitle,
    RPA.CommentCount AS TotalCommentsOnRecentPost,
    PCR.CloseReasonNames AS ReasonForClosure,
    MA.UserRank,
    MA.NetVotes
FROM Users U
JOIN RecentPostActivity RPA ON U.Id = RPA.OwnerUserId
LEFT JOIN PostCloseReasons PCR ON RPA.PostId = PCR.PostId
JOIN MostActiveUsers MA ON U.Id = MA.Id
WHERE MA.UserRank <= 10
ORDER BY MA.NetVotes DESC, U.Reputation DESC;

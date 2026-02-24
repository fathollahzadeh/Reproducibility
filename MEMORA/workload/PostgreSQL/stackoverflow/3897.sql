
WITH UserVoteSummary AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT P.Id) AS TotalPosts
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Posts P ON V.PostId = P.Id
    GROUP BY U.Id, U.DisplayName
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        COALESCE(COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END), 0) AS CommentCount,
        COUNT(DISTINCT V.UserId) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.Id, P.Title, P.CreationDate, P.Score
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.CreationDate AS ClosedDate,
        C.Name AS CloseReason
    FROM PostHistory PH
    JOIN CloseReasonTypes C ON CAST(PH.Comment AS INTEGER) = C.Id
    WHERE PH.PostHistoryTypeId = 10
),
RankedPosts AS (
    SELECT 
        PS.*,
        CASE 
            WHEN PS.VoteCount > 0 THEN 'Has Votes'
            ELSE 'No Votes'
        END AS VoteStatus
    FROM PostStatistics PS
    WHERE PS.Score > 10
)
SELECT 
    U.DisplayName,
    RP.Title,
    RP.CreationDate,
    RP.CommentCount,
    RP.VoteCount,
    RP.VoteStatus,
    CP.ClosedDate,
    CP.CloseReason
FROM UserVoteSummary U
JOIN RankedPosts RP ON U.TotalPosts > 0
LEFT JOIN ClosedPosts CP ON RP.PostId = CP.PostId
WHERE U.UpVotes - U.DownVotes > 5
ORDER BY U.DisplayName, RP.VoteCount DESC
OFFSET 5 ROWS
FETCH NEXT 10 ROWS ONLY;


WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
),
PostActivity AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COUNT(C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY P.Id, P.Title
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        COUNT(*) AS CloseCount,
        STRING_AGG(DISTINCT C.Name, ', ') AS CloseReasons
    FROM PostHistory PH
    JOIN CloseReasonTypes C ON PH.Comment::integer = C.Id
    WHERE PH.PostHistoryTypeId = 10
    GROUP BY PH.PostId
),
PostStats AS (
    SELECT 
        PA.PostId,
        PA.Title,
        PA.CommentCount,
        PA.UpVoteCount,
        PA.DownVoteCount,
        COALESCE(CP.CloseCount, 0) AS CloseCount,
        COALESCE(CP.CloseReasons, 'None') AS CloseReasons
    FROM PostActivity PA
    LEFT JOIN ClosedPosts CP ON PA.PostId = CP.PostId
)
SELECT 
    UR.UserId,
    UR.DisplayName,
    PS.PostId,
    PS.Title,
    PS.CommentCount,
    PS.UpVoteCount,
    PS.DownVoteCount,
    PS.CloseCount,
    PS.CloseReasons
FROM UserReputation UR
JOIN Posts P ON UR.UserId = P.OwnerUserId
JOIN PostStats PS ON P.Id = PS.PostId
WHERE UR.ReputationRank <= 10
ORDER BY UR.Reputation DESC, PS.UpVoteCount DESC, PS.CommentCount DESC;

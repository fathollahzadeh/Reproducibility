WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        DENSE_RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
    WHERE U.Reputation > 0
),

RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.PostTypeId,
        P.Title,
        P.Score,
        P.CreationDate,
        P.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RecentPostRank
    FROM Posts P
    WHERE P.CreationDate > cast('2024-10-01' as date) - INTERVAL '1 year'
),

PostVoteCounts AS (
    SELECT 
        P.Id AS PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        COUNT(V.Id) AS TotalVotes
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.Id
),

CloseReasons AS (
    SELECT 
        PH.PostId,
        STRING_AGG(DISTINCT CRT.Name, ', ') AS ReasonNames
    FROM PostHistory PH
    JOIN CloseReasonTypes CRT ON PH.Comment::int = CRT.Id
    WHERE PH.PostHistoryTypeId = 10
    GROUP BY PH.PostId
)

SELECT 
    U.DisplayName,
    U.Reputation,
    R.Title,
    R.Score,
    R.CreationDate AS PostCreationDate,
    COALESCE(V.UpVoteCount, 0) AS UpVoteCount,
    COALESCE(V.DownVoteCount, 0) AS DownVoteCount,
    COALESCE(CR.ReasonNames, 'Not Closed') AS CloseReasons,
    U.ReputationRank
FROM UserReputation U
LEFT JOIN RecentPosts R ON U.UserId = R.OwnerUserId AND R.RecentPostRank = 1
LEFT JOIN PostVoteCounts V ON R.PostId = V.PostId
LEFT JOIN CloseReasons CR ON R.PostId = CR.PostId
WHERE U.ReputationRank <= 10
ORDER BY U.Reputation DESC, R.CreationDate DESC
OFFSET 5 LIMIT 10;
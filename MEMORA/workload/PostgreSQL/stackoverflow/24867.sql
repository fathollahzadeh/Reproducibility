
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS Rank,
        CASE 
            WHEN U.Reputation IS NULL THEN 'No Reputation'
            WHEN U.Reputation > 1000 THEN 'High Reputation'
            WHEN U.Reputation BETWEEN 500 AND 1000 THEN 'Medium Reputation'
            ELSE 'Low Reputation'
        END AS ReputationCategory
    FROM Users U
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers
    FROM Posts P
    GROUP BY P.OwnerUserId
),
VotedPosts AS (
    SELECT 
        V.PostId,
        COUNT(V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes V
    GROUP BY V.PostId
),
RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        PS.TotalPosts,
        PS.Questions,
        PS.Answers,
        COALESCE(VP.VoteCount, 0) AS VoteCount,
        COALESCE(VP.UpVotes, 0) AS UpVotes,
        COALESCE(VP.DownVotes, 0) AS DownVotes,
        RANK() OVER (ORDER BY COALESCE(VP.VoteCount, 0) DESC) AS PostRank,
        P.OwnerUserId
    FROM Posts P
    LEFT JOIN PostStats PS ON P.OwnerUserId = PS.OwnerUserId
    LEFT JOIN VotedPosts VP ON P.Id = VP.PostId
    WHERE P.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
    AND (P.Score IS NOT NULL AND P.Score > 0)
)
SELECT 
    UR.UserId,
    UR.Reputation,
    UR.ReputationCategory,
    RP.PostId,
    RP.Title,
    RP.TotalPosts,
    RP.VoteCount,
    RP.UpVotes,
    RP.DownVotes,
    RP.PostRank
FROM UserReputation UR
JOIN RankedPosts RP ON UR.UserId = RP.OwnerUserId
WHERE UR.Rank <= 10 
AND RP.PostRank <= 5
ORDER BY RP.PostRank, UR.Reputation DESC;

WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        AVG(P.Score) AS AverageScore
    FROM Posts P
    GROUP BY P.OwnerUserId
),
TopUsers AS (
    SELECT 
        UR.DisplayName,
        UR.Reputation,
        PS.TotalPosts,
        PS.Questions,
        PS.Answers,
        PS.AverageScore
    FROM UserReputation UR
    JOIN PostStats PS ON UR.UserId = PS.OwnerUserId
    WHERE UR.Reputation > 1000
)
SELECT 
    U.DisplayName,
    COALESCE(PS.TotalPosts, 0) AS TotalPosts,
    COALESCE(PS.Questions, 0) AS Questions,
    COALESCE(PS.Answers, 0) AS Answers,
    COALESCE(AVG(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotesGiven,
    COALESCE(AVG(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotesGiven,
    CASE 
        WHEN PS.AverageScore IS NULL THEN 'No Posts' 
        WHEN PS.AverageScore > 5 THEN 'High Score'
        ELSE 'Low Score'
    END AS ScoreCategory
FROM Users U
LEFT JOIN PostStats PS ON U.Id = PS.OwnerUserId
LEFT JOIN Votes V ON U.Id = V.UserId
WHERE U.Reputation > 500 AND U.LastAccessDate > (cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year')
GROUP BY U.DisplayName, PS.TotalPosts, PS.Questions, PS.Answers, PS.AverageScore
HAVING COUNT(DISTINCT U.Id) >= 1
ORDER BY U.DisplayName;
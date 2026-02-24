WITH UserReputation AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
), 
PostSummary AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        AVG(P.Score) AS AverageScore
    FROM Posts P
    WHERE P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY P.OwnerUserId
), 
VoteSummary AS (
    SELECT 
        V.UserId, 
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes V
    GROUP BY V.UserId
)
SELECT 
    UR.DisplayName,
    UR.Reputation,
    PS.TotalPosts,
    PS.TotalQuestions,
    PS.AcceptedAnswers,
    PS.AverageScore,
    COALESCE(VS.TotalVotes, 0) AS TotalVotes,
    COALESCE(VS.UpVotes, 0) AS UpVotes,
    COALESCE(VS.DownVotes, 0) AS DownVotes,
    CASE 
        WHEN UR.ReputationRank <= 10 THEN 'Top Contributor'
        WHEN UR.ReputationRank <= 50 THEN 'Regular Contributor'
        ELSE 'New Contributor' 
    END AS ContributorLevel
FROM UserReputation UR
LEFT JOIN PostSummary PS ON UR.UserId = PS.OwnerUserId
LEFT JOIN VoteSummary VS ON UR.UserId = VS.UserId
WHERE UR.Reputation > 1000 
AND (PS.TotalPosts > 5 OR VS.TotalVotes > 10)
ORDER BY UR.Reputation DESC
LIMIT 100;
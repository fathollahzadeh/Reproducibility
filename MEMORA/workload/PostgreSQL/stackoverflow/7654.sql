
WITH UserStats AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT P.Id) AS QuestionCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
TopQuestions AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        U.DisplayName,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS ScoreRank
    FROM Posts P
    JOIN Users U ON P.OwnerUserId = U.Id
    WHERE P.PostTypeId = 1
),
RecentActivity AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        PH.UserDisplayName,
        PH.Comment,
        RANK() OVER (ORDER BY PH.CreationDate DESC) AS ActivityRank
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId IN (10, 11) 
)
SELECT 
    US.DisplayName AS UserName,
    US.Reputation,
    US.UpVotes AS TotalUpVotes,
    US.DownVotes AS TotalDownVotes,
    US.QuestionCount AS TotalQuestions,
    TQ.Title AS TopQuestionTitle,
    TQ.Score AS TopQuestionScore,
    TQ.ViewCount AS TopQuestionViewCount,
    RA.UserDisplayName AS RecentActivityUser,
    RA.Comment AS RecentActivityComment,
    RA.CreationDate AS RecentActivityDate
FROM UserStats US
JOIN TopQuestions TQ ON US.QuestionCount > 0
JOIN RecentActivity RA ON TQ.PostId = RA.PostId
WHERE TQ.ScoreRank <= 5
ORDER BY US.Reputation DESC, US.UpVotes DESC;

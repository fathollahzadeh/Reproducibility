
WITH UserMetrics AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation AS UserReputation
    FROM Users U
),
PostMetrics AS (
    SELECT 
        P.PostTypeId,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,         
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,       
        AVG(UM.UserReputation) AS AvgUserReputation    
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN UserMetrics UM ON P.OwnerUserId = UM.UserId
    WHERE P.CreationDate >= '2020-01-01' 
    GROUP BY P.PostTypeId
)

SELECT 
    PT.Name AS PostTypeName,
    PM.QuestionCount,
    PM.AnswerCount,
    PM.TotalUpVotes,
    PM.TotalDownVotes,
    PM.AvgUserReputation
FROM PostMetrics PM
JOIN PostTypes PT ON PM.PostTypeId = PT.Id
ORDER BY PM.PostTypeId;

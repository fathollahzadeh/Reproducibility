
WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation, 
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        COALESCE(AVG(CASE WHEN V.VoteTypeId = 2 THEN 1 END), 0) AS AverageUpVotes,
        COALESCE(AVG(CASE WHEN V.VoteTypeId = 3 THEN 1 END), 0) AS AverageDownVotes,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PostHistoryAggregates AS (
    SELECT 
        PH.PostId, 
        MIN(PH.CreationDate) AS FirstEditDate,
        COUNT(CASE WHEN PH.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenCount
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId
)
SELECT 
    US.DisplayName, 
    US.Reputation, 
    US.PostCount, 
    US.QuestionCount, 
    US.AnswerCount, 
    PHA.FirstEditDate,
    PHA.CloseReopenCount
FROM 
    UserStatistics US
LEFT JOIN 
    PostHistoryAggregates PHA ON US.UserId = PHA.PostId
WHERE 
    US.Reputation > (SELECT AVG(Reputation) FROM Users) 
    AND US.PostCount > 3
ORDER BY 
    US.UserRank, 
    US.DisplayName DESC;

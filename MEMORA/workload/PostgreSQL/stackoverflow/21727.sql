
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COUNT(DISTINCT P.Id) AS PostsCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AvgScore,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate
),
QuestionHistory AS (
    SELECT 
        Q.Id AS QuestionId,
        Q.Title,
        Q.CreationDate,
        (SELECT COUNT(*) FROM Comments C WHERE C.PostId = Q.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = Q.Id AND V.VoteTypeId = 2) AS UpVotes,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = Q.Id AND V.VoteTypeId = 3) AS DownVotes,
        (SELECT STRING_AGG(CAST(HT.PostHistoryTypeId AS VARCHAR), ', ') 
         FROM PostHistory HT 
         WHERE HT.PostId = Q.Id AND HT.CreationDate > Q.CreationDate) AS HistoryTypes
    FROM 
        Posts Q
    WHERE 
        Q.PostTypeId = 1
),
TopUsers AS (
    SELECT 
        UR.UserId,
        UR.DisplayName,
        UR.Reputation,
        UR.PostsCount,
        UR.QuestionsCount,
        UR.AnswersCount,
        RANK() OVER (ORDER BY UR.Reputation DESC) AS ReputationRank
    FROM 
        UserReputation UR
    WHERE 
        UR.Reputation > (SELECT AVG(Reputation) FROM Users)
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.PostsCount,
    QH.Title AS QuestionTitle,
    QH.CommentCount,
    QH.UpVotes,
    QH.DownVotes,
    QH.HistoryTypes
FROM 
    TopUsers TU
INNER JOIN 
    QuestionHistory QH ON QH.CommentCount > (SELECT AVG(CommentCount) FROM QuestionHistory WHERE HistoryTypes IS NOT NULL)
WHERE 
    TU.ReputationRank <= 5
ORDER BY 
    TU.Reputation DESC, QH.UpVotes DESC;

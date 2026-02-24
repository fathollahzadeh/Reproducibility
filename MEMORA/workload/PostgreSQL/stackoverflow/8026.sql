
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN P.Score ELSE 0 END) AS QuestionScore,
        SUM(CASE WHEN P.PostTypeId = 2 THEN P.Score ELSE 0 END) AS AnswerScore,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS QuestionCount,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS AnswerCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
UserVotes AS (
    SELECT 
        V.UserId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotesCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotesCount,
        COUNT(CASE WHEN V.VoteTypeId = 10 THEN 1 END) AS DeleteVotesCount
    FROM 
        Votes V
    GROUP BY 
        V.UserId
),
PostStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
)
SELECT 
    UR.UserId,
    UR.DisplayName,
    UR.Reputation,
    UR.BadgeCount,
    UV.UpVotesCount,
    UV.DownVotesCount,
    UV.DeleteVotesCount,
    PS.PostCount,
    PS.TotalViews,
    (UR.QuestionScore + UR.AnswerScore) AS TotalScore
FROM 
    UserReputation UR
LEFT JOIN 
    UserVotes UV ON UR.UserId = UV.UserId
LEFT JOIN 
    PostStatistics PS ON UR.UserId = PS.OwnerUserId
ORDER BY 
    TotalScore DESC, UR.Reputation DESC
LIMIT 100;

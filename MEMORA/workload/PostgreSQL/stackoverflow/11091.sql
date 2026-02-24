WITH PostStatistics AS (
    SELECT 
        P.OwnerUserId,
        P.PostTypeId,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        SUM(P.Score) AS TotalScore,
        SUM(P.ViewCount) AS TotalViews,
        COUNT(C) AS CommentCount,
        COUNT(DISTINCT V.Id) AS VoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.OwnerUserId, P.PostTypeId
),
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.DisplayName,
        U.CreationDate
    FROM 
        Users U
)

SELECT 
    UR.UserId,
    UR.DisplayName,
    UR.Reputation,
    PS.QuestionCount,
    PS.AnswerCount,
    PS.TotalScore,
    PS.TotalViews,
    PS.CommentCount,
    PS.VoteCount,
    UR.CreationDate
FROM 
    UserReputation UR
LEFT JOIN 
    PostStatistics PS ON UR.UserId = PS.OwnerUserId
WHERE 
    UR.Reputation > 0
ORDER BY 
    UR.Reputation DESC;
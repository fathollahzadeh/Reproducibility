
WITH UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(COALESCE(C.VoteCount, 0)) AS TotalVotes,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        (SELECT 
            PostId, 
            COUNT(*) AS VoteCount 
        FROM 
            Votes 
        GROUP BY 
            PostId) C ON P.Id = C.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
)
SELECT 
    E.UserId,
    E.DisplayName,
    E.QuestionCount,
    E.AnswerCount,
    E.TotalVotes,
    E.BadgeCount,
    R.Reputation,
    R.ReputationRank
FROM 
    UserEngagement E
JOIN 
    UserReputation R ON E.UserId = R.UserId
WHERE 
    E.QuestionCount > 0
ORDER BY 
    E.TotalVotes DESC, 
    R.ReputationRank ASC
FETCH FIRST 100 ROWS ONLY;

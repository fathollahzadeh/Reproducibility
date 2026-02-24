WITH UserMetrics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(COALESCE(V.VoteAmount, 0)) AS TotalVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        (SELECT 
             PostId, 
             SUM(CASE WHEN VoteTypeId = 2 THEN 1 WHEN VoteTypeId = 3 THEN -1 ELSE 0 END) AS VoteAmount 
         FROM 
             Votes 
         GROUP BY 
             PostId) V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
)
SELECT 
    UMetrics.UserId,
    UMetrics.DisplayName,
    UMetrics.PostCount,
    UMetrics.QuestionCount,
    UMetrics.AnswerCount,
    UMetrics.TotalVotes,
    B.Count AS BadgeCount
FROM 
    UserMetrics UMetrics
LEFT JOIN 
    (SELECT UserId, COUNT(*) AS Count FROM Badges GROUP BY UserId) B ON UMetrics.UserId = B.UserId
ORDER BY 
    UMetrics.TotalVotes DESC;
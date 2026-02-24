
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    U.CreationDate,
    U.LastAccessDate,
    COUNT(DISTINCT P.Id) AS PostCount,
    COUNT(DISTINCT CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS QuestionCount,
    COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS AnswerCount,
    SUM(COALESCE(P.Score, 0)) AS TotalScore,
    SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
    U.UpVotes,
    U.DownVotes
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
GROUP BY 
    U.Id, U.DisplayName, U.Reputation, U.CreationDate, U.LastAccessDate, U.UpVotes, U.DownVotes
ORDER BY 
    PostCount DESC, U.Reputation DESC
LIMIT 100;

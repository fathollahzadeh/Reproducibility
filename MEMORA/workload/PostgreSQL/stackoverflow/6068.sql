
WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 AND P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END), 0) AS AcceptedAnswers,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        RANK() OVER (ORDER BY COUNT(P.Id) DESC) AS UserRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
), 
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        QuestionCount,
        AnswerCount,
        AcceptedAnswers,
        UpVotes,
        DownVotes,
        UserRank
    FROM 
        UserPostStats
    WHERE 
        UserRank <= 10
)
SELECT 
    TU.DisplayName,
    TU.PostCount,
    TU.QuestionCount,
    TU.AnswerCount,
    TU.AcceptedAnswers,
    TU.UpVotes,
    TU.DownVotes,
    U.Reputation,
    (SELECT COUNT(*) FROM Badges B WHERE B.UserId = TU.UserId) AS BadgeCount,
    (SELECT COUNT(*) FROM Comments C WHERE C.UserId = TU.UserId) AS CommentCount
FROM 
    TopUsers TU
JOIN 
    Users U ON TU.UserId = U.Id
ORDER BY 
    TU.PostCount DESC, TU.UserId;

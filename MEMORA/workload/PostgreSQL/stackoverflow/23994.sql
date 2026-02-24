
WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        COALESCE(COUNT(DISTINCT C.Id), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN V.CreationDate IS NOT NULL THEN 1 ELSE 0 END), 0) AS TotalVotes,
        AVG(COALESCE(P.Score, 0)) AS AverageScore
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (2, 3) 
    GROUP BY U.Id, U.DisplayName
),
PopularUsers AS (
    SELECT 
        UserId,
        DisplayName,
        QuestionCount,
        AnswerCount,
        CommentCount,
        TotalVotes,
        AverageScore,
        RANK() OVER (ORDER BY TotalVotes DESC) AS VoteRank,
        RANK() OVER (ORDER BY AnswerCount DESC) AS AnswerRank
    FROM UserPostStats
    WHERE AverageScore > 0 AND QuestionCount > 5
),
BannedUsers AS (
    SELECT DISTINCT UserId 
    FROM Votes
    WHERE VoteTypeId = 10 
),
FinalResults AS (
    SELECT 
        PU.UserId,
        PU.DisplayName,
        PU.QuestionCount,
        PU.AnswerCount,
        PU.CommentCount,
        PU.TotalVotes,
        PU.AverageScore,
        CASE 
            WHEN BU.UserId IS NOT NULL THEN 'Banned'
            ELSE 'Active' 
        END AS UserStatus
    FROM PopularUsers PU
    LEFT JOIN BannedUsers BU ON PU.UserId = BU.UserId
)
SELECT 
    UserId,
    DisplayName,
    QuestionCount,
    AnswerCount,
    CommentCount,
    TotalVotes,
    AverageScore,
    UserStatus
FROM FinalResults
WHERE UserStatus = 'Active'
ORDER BY AverageScore DESC, TotalVotes DESC;

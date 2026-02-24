WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS TotalAnswers
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        UpVotes - DownVotes AS NetVotes,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        RANK() OVER (ORDER BY UpVotes DESC) AS VoteRank,
        DENSE_RANK() OVER (ORDER BY TotalPosts DESC) AS PostRank
    FROM UserStats
    WHERE TotalPosts > 0
),
PostSummary AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        AVG(P.Score) AS AverageScore,
        MIN(P.CreationDate) AS FirstPostDate,
        MAX(P.CreationDate) AS LastPostDate
    FROM Posts P
    GROUP BY P.OwnerUserId
)
SELECT 
    U.DisplayName,
    COALESCE(S.PostCount, 0) AS PostCount,
    COALESCE(S.AverageScore, 0) AS AverageScore,
    U.UpVotes,
    U.DownVotes,
    U.TotalQuestions,
    U.TotalAnswers,
    COALESCE(T.NetVotes, 0) AS NetVotes,
    T.VoteRank,
    T.PostRank,
    COALESCE(COUNT(DISTINCT C.Id), 0) AS CommentCount
FROM UserStats U
LEFT JOIN PostSummary S ON U.UserId = S.OwnerUserId
LEFT JOIN TopUsers T ON U.UserId = T.UserId
LEFT JOIN Comments C ON U.UserId = C.UserId
GROUP BY U.DisplayName, S.PostCount, S.AverageScore, U.UpVotes, U.DownVotes, U.TotalQuestions, U.TotalAnswers, T.NetVotes, T.VoteRank, T.PostRank
HAVING (COALESCE(T.NetVotes, 0) >= 10 OR SUM(COALESCE(C.Score, 0)) >= 50)
ORDER BY T.VoteRank, PostCount DESC
LIMIT 100;

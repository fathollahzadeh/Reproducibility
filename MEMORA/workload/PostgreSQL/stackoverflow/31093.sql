
WITH RECURSIVE UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        RANK() OVER (ORDER BY COUNT(P.Id) DESC) AS UserRank
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalViews,
        UserRank
    FROM UserPostStats
    WHERE PostCount > 10
    ORDER BY UserRank
    LIMIT 10
),
PostVoteStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE P.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
    GROUP BY P.OwnerUserId
),
TopPostVoters AS (
    SELECT 
        U.Id,
        U.DisplayName,
        COALESCE(V.VoteCount, 0) AS TotalVotes,
        COALESCE(V.UpVotes, 0) AS UpVoteCount,
        COALESCE(V.DownVotes, 0) AS DownVoteCount
    FROM Users U
    LEFT JOIN PostVoteStats V ON U.Id = V.OwnerUserId
    WHERE COALESCE(V.VoteCount, 0) > 5
)
SELECT 
    TU.DisplayName AS TopUser,
    TU.QuestionCount,
    TU.AnswerCount,
    TU.TotalViews,
    TPV.TotalVotes,
    TPV.UpVoteCount,
    TPV.DownVoteCount
FROM TopUsers TU
LEFT JOIN TopPostVoters TPV ON TU.UserId = TPV.Id
ORDER BY TU.UserRank, TPV.TotalVotes DESC;

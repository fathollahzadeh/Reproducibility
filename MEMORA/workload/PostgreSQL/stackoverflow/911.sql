
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COUNT(DISTINCT P.Id) AS PostCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        SUM(COALESCE(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END, 0)) AS UpVotes,
        SUM(COALESCE(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END, 0)) AS DownVotes
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.DisplayName, U.Reputation, U.CreationDate
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        AnswerCount,
        QuestionCount,
        UpVotes,
        DownVotes,
        DENSE_RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM UserStats
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        U.DisplayName AS Author,
        COALESCE(COUNT(C.Id), 0) AS CommentCount
    FROM Posts P
    LEFT JOIN Users U ON P.OwnerUserId = U.Id
    LEFT JOIN Comments C ON P.Id = C.PostId
    WHERE P.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '30 days'
    GROUP BY P.Id, P.Title, P.CreationDate, U.DisplayName
),
RankedPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Author,
        CommentCount,
        RANK() OVER (ORDER BY CreationDate DESC) AS PostRank
    FROM RecentPosts
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.PostCount,
    TU.AnswerCount,
    TU.QuestionCount,
    TU.UpVotes,
    TU.DownVotes,
    RP.Title,
    RP.CreationDate,
    RP.CommentCount,
    RP.PostRank
FROM TopUsers TU
LEFT JOIN RankedPosts RP ON TU.DisplayName = RP.Author
WHERE TU.ReputationRank <= 10
ORDER BY TU.Reputation DESC, RP.CreationDate DESC;


WITH RecursivePostStats AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        P.AcceptedAnswerId,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS UserPostRank
    FROM
        Posts P
    WHERE
        P.PostTypeId = 1 
),
TopUsers AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS QuestionCount
    FROM
        Users U
    JOIN
        Posts P ON U.Id = P.OwnerUserId
    WHERE
        P.PostTypeId = 1 
    GROUP BY
        U.Id, U.DisplayName, U.Reputation
    HAVING
        COUNT(DISTINCT P.Id) > 5
),
UserWithHighestReputation AS (
    SELECT
        UserId,
        DisplayName,
        Reputation
    FROM
        TopUsers
    ORDER BY
        Reputation DESC
    LIMIT 1
),
PostInteractions AS (
    SELECT
        P.Id AS PostId,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM
        Posts P
    LEFT JOIN
        Comments C ON P.Id = C.PostId
    LEFT JOIN
        Votes V ON P.Id = V.PostId
    WHERE
        P.OwnerUserId = (SELECT UserId FROM UserWithHighestReputation)
    GROUP BY
        P.Id
),
FinalReport AS (
    SELECT
        PS.PostId,
        PS.Title,
        U.DisplayName AS OwnerDisplayName,
        PS.ViewCount,
        PS.Score,
        PI.CommentCount,
        PI.UpVoteCount,
        PI.DownVoteCount
    FROM
        RecursivePostStats PS
    JOIN
        Users U ON PS.OwnerUserId = U.Id
    LEFT JOIN
        PostInteractions PI ON PS.PostId = PI.PostId
    WHERE
        PS.UserPostRank = 1 
)
SELECT
    FR.PostId,
    FR.Title,
    FR.OwnerDisplayName,
    FR.ViewCount,
    FR.Score,
    COALESCE(FR.CommentCount, 0) AS CommentCount,
    COALESCE(FR.UpVoteCount, 0) AS UpVoteCount,
    COALESCE(FR.DownVoteCount, 0) AS DownVoteCount
FROM
    FinalReport FR
ORDER BY
    FR.Score DESC, FR.ViewCount DESC;

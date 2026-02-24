WITH UserVoteSummary AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT P.Id) AS PostCount
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
        *,
        (UpVotes - DownVotes) AS VoteBalance
    FROM
        UserVoteSummary
    ORDER BY
        VoteBalance DESC
    LIMIT 10
)

SELECT
    T.DisplayName,
    T.UpVotes,
    T.DownVotes,
    T.VoteBalance,
    P.CreationDate AS PostCreationDate,
    P.Title AS PostTitle,
    P.ViewCount,
    P.Score
FROM
    TopUsers T
JOIN
    Posts P ON T.UserId = P.OwnerUserId
ORDER BY
    T.VoteBalance DESC, P.ViewCount DESC;
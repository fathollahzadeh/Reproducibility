WITH RECURSIVE UserVotes AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        V.PostId,
        V.VoteTypeId,
        V.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY V.CreationDate DESC) AS VoteRank
    FROM
        Users U
    JOIN Votes V ON U.Id = V.UserId
    WHERE
        U.Reputation > 1000
),
PostStats AS (
    SELECT
        P.Id AS PostId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        COUNT(DISTINCT C.UserId) AS UniqueCommenters
    FROM
        Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY
        P.Id
),
RecentActivity AS (
    SELECT
        P.Id AS PostId,
        P.CreationDate,
        P.LastActivityDate,
        P.Title,        
        COALESCE(H.Comment, 'No comments') AS LastEditComment,
        ROW_NUMBER() OVER (ORDER BY P.LastActivityDate DESC) AS ActivityRank
    FROM
        Posts P
    LEFT JOIN PostHistory H ON P.Id = H.PostId AND H.PostHistoryTypeId = 24 
)
SELECT
    PS.PostId,
    R.Title,
    R.CreationDate,
    R.LastActivityDate,
    PS.UpVotes,
    PS.DownVotes,
    PS.CommentCount,
    PS.TotalScore,
    PS.UniqueCommenters,
    UA.DisplayName AS LastVoter,
    UA.VoteTypeId AS LastVoteType,
    R.LastEditComment
FROM
    PostStats PS
JOIN RecentActivity R ON PS.PostId = R.PostId
LEFT JOIN UserVotes UA ON UA.PostId = PS.PostId AND UA.VoteRank = 1
WHERE
    PS.UpVotes - PS.DownVotes > 5 
ORDER BY
    PS.TotalScore DESC, R.LastActivityDate DESC
LIMIT 100;
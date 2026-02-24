WITH UserVoteStats AS (
    SELECT
        U.Id AS UserId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount
    FROM
        Users U
    LEFT JOIN
        Votes V ON U.Id = V.UserId
    LEFT JOIN
        Posts P ON V.PostId = P.Id
    LEFT JOIN
        Comments C ON P.Id = C.PostId
    GROUP BY
        U.Id
),
PostStats AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        COALESCE(PS.UpVotes, 0) AS TotalUpVotes,
        COALESCE(PS.DownVotes, 0) AS TotalDownVotes,
        COALESCE(PS.PostCount, 0) AS TotalPosts,
        COALESCE(PS.CommentCount, 0) AS TotalComments
    FROM
        Posts P
    JOIN
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN
        UserVoteStats PS ON U.Id = PS.UserId
    WHERE
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
        AND P.Score > 0
    ORDER BY
        P.Score DESC,
        P.ViewCount DESC
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        OwnerDisplayName,
        Score,
        ViewCount,
        ROW_NUMBER() OVER (ORDER BY Score DESC, ViewCount DESC) AS Rank
    FROM 
        PostStats
    WHERE 
        TotalPosts > 5
)
SELECT 
    T.PostId,
    T.Title,
    T.OwnerDisplayName,
    T.Score,
    T.ViewCount
FROM 
    TopPosts T
WHERE 
    Rank <= 10
ORDER BY 
    T.Score DESC;
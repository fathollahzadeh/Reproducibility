
WITH RankedPosts AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        U.DisplayName AS OwnerName,
        P.ViewCount,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS Rank
    FROM
        Posts P
    LEFT JOIN
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN
        Votes V ON P.Id = V.PostId
    LEFT JOIN
        Comments C ON P.Id = C.PostId
    WHERE
        P.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '30 days'
    GROUP BY
        P.Id, U.DisplayName, P.Title, P.CreationDate, P.Score, P.ViewCount
),
TopPosts AS (
    SELECT
        RP.PostId,
        RP.Title,
        RP.CreationDate,
        RP.Score,
        RP.OwnerName,
        RP.ViewCount,
        RP.UpVotes,
        RP.DownVotes,
        RP.CommentCount
    FROM
        RankedPosts RP
    WHERE
        RP.Rank <= 10
)
SELECT
    TP.Title,
    TP.OwnerName,
    TP.CreationDate,
    TP.Score,
    TP.ViewCount,
    TP.UpVotes,
    TP.DownVotes,
    TP.CommentCount,
    T.TagName
FROM
    TopPosts TP
LEFT JOIN
    LATERAL (
        SELECT
            unnest(string_to_array(substring(TP.Title, 2, length(TP.Title) - 2), '><')) AS TagName
    ) T ON TRUE
ORDER BY
    TP.Score DESC;


WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerName,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 WHEN V.VoteTypeId = 3 THEN -1 ELSE 0 END) AS NetVotes,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.CreationDate DESC) AS Rank
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 YEAR'
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, U.DisplayName, P.PostTypeId
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        OwnerName,
        CommentCount,
        NetVotes
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
)
SELECT 
    TP.*,
    (SELECT COUNT(*) FROM PostHistory PH WHERE PH.PostId = TP.PostId) AS HistoryCount,
    (SELECT STRING_AGG(DISTINCT T.TagName, ', ') FROM Posts P JOIN Tags T ON P.Tags LIKE CONCAT('%', T.TagName, '%') WHERE P.Id = TP.PostId) AS AssociatedTags
FROM 
    TopPosts TP
ORDER BY 
    TP.NetVotes DESC, TP.Score DESC;

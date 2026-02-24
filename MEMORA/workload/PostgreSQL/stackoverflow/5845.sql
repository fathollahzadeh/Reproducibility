WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        U.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.ViewCount DESC) AS RankScore,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS Downvotes
    FROM 
        Posts P
    INNER JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score, U.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        ViewCount,
        Score,
        OwnerDisplayName,
        Upvotes,
        Downvotes,
        RankScore
    FROM 
        RankedPosts
    WHERE 
        RankScore <= 10
)
SELECT 
    T.PostId,
    T.Title,
    T.CreationDate,
    T.ViewCount,
    T.Score,
    T.OwnerDisplayName,
    T.Upvotes,
    T.Downvotes,
    (T.Upvotes - T.Downvotes) AS NetVotes
FROM 
    TopPosts T
ORDER BY 
    T.Score DESC, T.ViewCount DESC;
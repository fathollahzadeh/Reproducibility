WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        U.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS RankScore
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= (cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year') 
        AND P.ViewCount > 100
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        ViewCount,
        Score,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        RankScore <= 5
),
PostStats AS (
    SELECT 
        PP.PostId,
        PP.Title,
        PP.CreationDate,
        PP.ViewCount,
        PP.Score,
        PP.OwnerDisplayName,
        COUNT(C.Id) AS CommentsCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        TopPosts PP
    LEFT JOIN 
        Comments C ON PP.PostId = C.PostId
    LEFT JOIN 
        Votes V ON PP.PostId = V.PostId
    GROUP BY 
        PP.PostId, PP.Title, PP.CreationDate, PP.ViewCount, PP.Score, PP.OwnerDisplayName
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.ViewCount,
    PS.Score,
    PS.OwnerDisplayName,
    PS.CommentsCount,
    PS.UpVotes,
    PS.DownVotes,
    (PS.UpVotes - PS.DownVotes) AS VoteBalance 
FROM 
    PostStats PS
ORDER BY 
    PS.Score DESC, PS.ViewCount DESC;
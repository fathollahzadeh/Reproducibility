
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        U.DisplayName AS OwnerDisplayName,
        COUNT(C.Id) AS CommentCount,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.ViewCount DESC) AS RankScore
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Title, P.ViewCount, P.Score, U.DisplayName
),
TopPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.ViewCount,
        RP.Score,
        RP.OwnerDisplayName
    FROM 
        RankedPosts RP
    WHERE 
        RP.RankScore <= 10
)
SELECT 
    TP.PostId,
    TP.Title,
    TP.ViewCount,
    TP.Score,
    TP.OwnerDisplayName,
    PT.Name AS PostType,
    COUNT(V.Id) AS TotalVotes,
    SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
    SUM(CASE WHEN V.VoteTypeId IN (6, 10) THEN 1 ELSE 0 END) AS CloseVotes
FROM 
    TopPosts TP
LEFT JOIN 
    Votes V ON TP.PostId = V.PostId
LEFT JOIN 
    PostTypes PT ON TP.PostId = PT.Id
GROUP BY 
    TP.PostId, TP.Title, TP.ViewCount, TP.Score, TP.OwnerDisplayName, PT.Name
ORDER BY 
    TP.Score DESC, TP.ViewCount DESC;

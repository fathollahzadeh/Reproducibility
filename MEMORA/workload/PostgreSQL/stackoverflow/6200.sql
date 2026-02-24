
WITH RankedPosts AS (
    SELECT 
        P.Id, 
        P.Title, 
        P.CreationDate, 
        P.ViewCount, 
        P.Score, 
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS Rank
    FROM 
        Posts P
    INNER JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    AND 
        P.ViewCount > 100
),
TopPosts AS (
    SELECT 
        RP.Id, 
        RP.Title, 
        RP.CreationDate, 
        RP.ViewCount, 
        RP.Score, 
        RP.OwnerDisplayName,
        COUNT(C.Id) AS CommentCount 
    FROM 
        RankedPosts RP
    LEFT JOIN 
        Comments C ON RP.Id = C.PostId
    WHERE 
        RP.Rank <= 5
    GROUP BY 
        RP.Id, RP.Title, RP.CreationDate, RP.ViewCount, RP.Score, RP.OwnerDisplayName
),
PostVoteDetails AS (
    SELECT 
        P.Id AS PostId, 
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id
)
SELECT 
    TP.Title, 
    TP.CreationDate, 
    TP.ViewCount, 
    TP.Score, 
    TP.OwnerDisplayName, 
    TP.CommentCount, 
    PVD.UpVotes, 
    PVD.DownVotes
FROM 
    TopPosts TP
JOIN 
    PostVoteDetails PVD ON TP.Id = PVD.PostId
ORDER BY 
    TP.Score DESC, 
    TP.CommentCount DESC;

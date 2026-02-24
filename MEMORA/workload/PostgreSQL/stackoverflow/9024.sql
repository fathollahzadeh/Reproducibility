WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        U.DisplayName AS OwnerDisplayName,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId IN (1, 2) 
),
PostDetails AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.OwnerDisplayName,
        RP.CreationDate,
        RP.ViewCount,
        RP.Score,
        COUNT(C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        RankedPosts RP
    LEFT JOIN 
        Comments C ON RP.PostId = C.PostId
    LEFT JOIN 
        Votes V ON RP.PostId = V.PostId
    WHERE 
        RP.PostRank = 1 
    GROUP BY 
        RP.PostId, RP.Title, RP.OwnerDisplayName, RP.CreationDate, RP.ViewCount, RP.Score
),
TopPosts AS (
    SELECT 
        PD.PostId,
        PD.Title,
        PD.OwnerDisplayName,
        PD.CreationDate,
        PD.ViewCount,
        PD.Score,
        PD.CommentCount,
        PD.UpVoteCount,
        PD.DownVoteCount,
        RANK() OVER (ORDER BY PD.Score DESC, PD.ViewCount DESC) AS RankScore
    FROM 
        PostDetails PD
)
SELECT 
    TP.PostId,
    TP.Title,
    TP.OwnerDisplayName,
    TP.CreationDate,
    TP.ViewCount,
    TP.Score,
    TP.CommentCount,
    TP.UpVoteCount,
    TP.DownVoteCount
FROM 
    TopPosts TP
WHERE 
    TP.RankScore <= 10 
ORDER BY 
    TP.RankScore;
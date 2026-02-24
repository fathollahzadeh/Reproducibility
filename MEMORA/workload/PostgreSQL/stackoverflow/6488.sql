
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        COUNT(C.Id) AS CommentCount,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS RankByScore,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS LatestPostRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        P.Id, P.Title, P.Score, P.ViewCount, U.DisplayName
), TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        Score, 
        ViewCount, 
        OwnerDisplayName, 
        CommentCount 
    FROM 
        RankedPosts
    WHERE 
        RankByScore <= 5
)
SELECT 
    TP.Title,
    TP.Score,
    TP.ViewCount,
    TP.OwnerDisplayName,
    TP.CommentCount,
    PT.Name AS PostTypeName,
    COUNT(PH.Id) AS HistoryCount,
    AVG(V.BountyAmount) AS AverageBounty
FROM 
    TopPosts TP
JOIN 
    PostTypes PT ON TP.PostId IN (SELECT Id FROM Posts WHERE PostTypeId = PT.Id)
LEFT JOIN 
    PostHistory PH ON TP.PostId = PH.PostId
LEFT JOIN 
    Votes V ON TP.PostId = V.PostId AND V.VoteTypeId = 8 
GROUP BY 
    TP.Title, TP.Score, TP.ViewCount, TP.OwnerDisplayName, TP.CommentCount, PT.Name, TP.PostId
ORDER BY 
    TP.Score DESC, TP.ViewCount DESC;

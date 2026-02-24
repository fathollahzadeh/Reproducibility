
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.CreationDate DESC) AS Rank
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
        AND P.Score > 0
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score
),
TopPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.CreationDate,
        RP.ViewCount,
        RP.Score,
        RP.CommentCount,
        RP.UpVoteCount,
        RP.DownVoteCount
    FROM 
        RankedPosts RP
    WHERE 
        RP.Rank <= 5
)
SELECT 
    TP.PostId,
    TP.Title,
    TP.CreationDate,
    TP.ViewCount,
    TP.Score,
    TP.CommentCount,
    TP.UpVoteCount,
    TP.DownVoteCount,
    U.DisplayName AS OwnerDisplayName,
    U.Reputation,
    BP.Name AS BadgeName,
    COUNT(DISTINCT PL.RelatedPostId) AS RelatedPostCount
FROM 
    TopPosts TP
JOIN 
    Users U ON TP.PostId = U.Id
LEFT JOIN 
    Badges BP ON U.Id = BP.UserId
LEFT JOIN 
    PostLinks PL ON TP.PostId = PL.PostId
GROUP BY 
    TP.PostId, TP.Title, U.DisplayName, TP.CreationDate, TP.ViewCount, TP.Score, 
    TP.CommentCount, TP.UpVoteCount, TP.DownVoteCount, U.Reputation, BP.Name
ORDER BY 
    TP.Score DESC, TP.CreationDate DESC;

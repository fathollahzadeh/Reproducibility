
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(CASE WHEN V.Id IS NOT NULL THEN 1 END) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.CreationDate DESC) AS Rank
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON C.PostId = P.Id
    LEFT JOIN 
        Votes V ON V.PostId = P.Id
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, U.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        OwnerDisplayName,
        CommentCount,
        VoteCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
)
SELECT 
    TP.PostId,
    TP.Title,
    TP.CreationDate,
    TP.Score,
    TP.ViewCount,
    TP.OwnerDisplayName,
    TP.CommentCount,
    TP.VoteCount,
    COALESCE(B.Name, 'No Badge') AS UserBadge,
    PH.PostHistoryTypeId,
    PH.CreationDate AS HistoryDate
FROM 
    TopPosts TP
LEFT JOIN 
    Users U ON TP.OwnerDisplayName = U.DisplayName
LEFT JOIN 
    Badges B ON U.Id = B.UserId
LEFT JOIN 
    PostHistory PH ON TP.PostId = PH.PostId
WHERE 
    PH.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 month'
ORDER BY 
    TP.Score DESC, TP.CreationDate DESC;

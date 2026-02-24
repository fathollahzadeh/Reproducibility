WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT PH.Id) AS HistoryCount,
        ROW_NUMBER() OVER (ORDER BY P.Score DESC, P.CreationDate DESC) AS Rank
    FROM 
        Posts P
    INNER JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    WHERE 
        P.PostTypeId IN (1, 2) 
    GROUP BY 
        P.Id, P.Title, P.Score, P.CreationDate, U.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Score,
        CreationDate,
        OwnerDisplayName,
        CommentCount,
        HistoryCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 100
)
SELECT 
    TP.Title,
    TP.Score,
    TP.OwnerDisplayName,
    TP.CommentCount,
    (SELECT COUNT(*) FROM Votes V WHERE V.PostId = TP.PostId AND V.VoteTypeId = 2) AS UpVotes,
    (SELECT COUNT(*) FROM Votes V WHERE V.PostId = TP.PostId AND V.VoteTypeId = 3) AS DownVotes,
    (SELECT STRING_AGG(PH.Comment, '; ') FROM PostHistory PH WHERE PH.PostId = TP.PostId) AS PostHistoryComments
FROM 
    TopPosts TP
ORDER BY 
    TP.Score DESC, 
    TP.CreationDate ASC;
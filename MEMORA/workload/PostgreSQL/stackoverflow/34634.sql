
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.Body,
        U.DisplayName AS OwnerDisplayName,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        SUM(V.BountyAmount) AS TotalBounty,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS Rank
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON C.PostId = P.Id
    LEFT JOIN 
        Votes V ON V.PostId = P.Id AND V.VoteTypeId IN (8, 9) 
    WHERE 
        P.CreationDate > CURRENT_TIMESTAMP - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.Body, U.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        Body,
        OwnerDisplayName,
        CommentCount,
        TotalBounty
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
),
PostHistoryWithComments AS (
    SELECT
        PH.PostId,
        PH.RevisionGUID,
        PH.CreationDate AS HistoryDate,
        PH.UserDisplayName,
        PH.Comment,
        PH.Text,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (10, 11, 12) 
)
SELECT 
    TP.Title AS TopPostTitle,
    TP.OwnerDisplayName,
    TP.CreationDate AS PostCreationDate,
    TP.CommentCount,
    TP.TotalBounty,
    PH.HistoryDate,
    PH.UserDisplayName AS Editor,
    PH.Comment AS HistoryComment,
    PH.Text AS HistoryText
FROM 
    TopPosts TP
LEFT JOIN 
    PostHistoryWithComments PH ON TP.PostId = PH.PostId AND PH.HistoryRank = 1 
WHERE 
    TP.CommentCount > 5 
ORDER BY 
    TP.Score DESC, TP.CreationDate DESC;

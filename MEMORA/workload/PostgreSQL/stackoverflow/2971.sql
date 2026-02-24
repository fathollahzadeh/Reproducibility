
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpvoteCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownvoteCount,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) DESC) AS Rank
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.Title, P.Body, P.CreationDate, U.DisplayName, P.PostTypeId
),
RecentComments AS (
    SELECT 
        C.PostId,
        COUNT(C.Id) AS CommentCount
    FROM 
        Comments C
    WHERE 
        C.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        C.PostId
),
PostHistoryChanges AS (
    SELECT 
        PH.PostId,
        PH.PostHistoryTypeId,
        PH.CreationDate,
        PHT.Name AS ChangeType,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS ChangeRank
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
),
FilteredPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.Body,
        RP.CreationDate,
        RP.OwnerDisplayName,
        RP.UpvoteCount,
        RP.DownvoteCount,
        RC.CommentCount,
        COALESCE(PHC.ChangeType, 'No Changes') AS MostRecentChange
    FROM 
        RankedPosts RP
    LEFT JOIN 
        RecentComments RC ON RP.PostId = RC.PostId
    LEFT JOIN 
        PostHistoryChanges PHC ON RP.PostId = PHC.PostId AND PHC.ChangeRank = 1
    WHERE 
        RP.Rank <= 5
)
SELECT 
    FP.PostId,
    FP.Title,
    FP.Body,
    FP.CreationDate,
    FP.OwnerDisplayName,
    FP.UpvoteCount,
    FP.DownvoteCount,
    FP.CommentCount,
    FP.MostRecentChange
FROM 
    FilteredPosts FP
ORDER BY 
    FP.UpvoteCount DESC, 
    FP.CommentCount DESC;

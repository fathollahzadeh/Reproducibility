WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY P.Id ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 month'
    GROUP BY 
        P.Id, P.Title, P.ViewCount, P.CreationDate, U.DisplayName
),
TopComments AS (
    SELECT 
        C.Id AS CommentId,
        C.PostId,
        C.Text,
        C.UserDisplayName,
        ROW_NUMBER() OVER (PARTITION BY C.PostId ORDER BY C.CreationDate DESC) AS CommentRank
    FROM 
        Comments C
    WHERE 
        C.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 week'
),
PostHistoryAggregate AS (
    SELECT 
        PH.PostId,
        STRING_AGG(PHT.Name, ', ') AS HistoryTypes,
        COUNT(PH.Id) AS HistoryCount
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY 
        PH.PostId
)
SELECT 
    RP.Title,
    RP.ViewCount,
    RP.CreationDate,
    RP.OwnerDisplayName,
    RP.CommentCount,
    TCA.CommentText,
    TCA.UserDisplayName AS CommentUser,
    PHA.HistoryTypes,
    PHA.HistoryCount
FROM 
    RankedPosts RP
LEFT JOIN 
    (SELECT 
         TC.CommentId,
         TC.Text AS CommentText,
         TC.UserDisplayName,
         TC.PostId
     FROM 
         TopComments TC
     WHERE 
         TC.CommentRank = 1) TCA ON RP.PostId = TCA.PostId
LEFT JOIN 
    PostHistoryAggregate PHA ON RP.PostId = PHA.PostId
WHERE 
    RP.PostRank = 1
ORDER BY 
    RP.ViewCount DESC
LIMIT 10;
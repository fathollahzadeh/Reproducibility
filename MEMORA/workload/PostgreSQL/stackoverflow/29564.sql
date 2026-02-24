
WITH PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.CreationDate,
        U.DisplayName AS OwnerName,
        P.ViewCount,
        P.Score,
        P.Tags,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(CASE WHEN V.Id IS NOT NULL THEN 1 END) AS VoteCount,
        STRING_AGG(DISTINCT B.Name, ', ') AS BadgeNames
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    WHERE 
        P.CreationDate > '2023-01-01' 
    GROUP BY 
        P.Id, P.Title, P.Body, P.CreationDate, U.DisplayName, P.ViewCount, P.Score, P.Tags
),

PostHistories AS (
    SELECT 
        PH.PostId,
        STRING_AGG(CASE WHEN PHT.Name = 'Edit Title' THEN PH.Text END, '; ') AS EditedTitles,
        STRING_AGG(CASE WHEN PHT.Name = 'Edit Body' THEN PH.Text END, '; ') AS EditedBodies,
        STRING_AGG(CASE WHEN PHT.Name = 'Initial Tags' THEN PH.Text END, '; ') AS InitialTags
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY 
        PH.PostId
)

SELECT 
    PD.PostId,
    PD.Title,
    PD.OwnerName,
    PD.CreationDate,
    PD.ViewCount,
    PD.Score,
    PD.Tags,
    PD.CommentCount,
    PD.VoteCount,
    PD.BadgeNames,
    PH.EditedTitles,
    PH.EditedBodies,
    PH.InitialTags
FROM 
    PostDetails PD
LEFT JOIN 
    PostHistories PH ON PD.PostId = PH.PostId
ORDER BY 
    PD.ViewCount DESC,
    PD.Score DESC;

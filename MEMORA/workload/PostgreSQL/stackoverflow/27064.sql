
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Tags,
        P.CreationDate,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        B.Name AS BadgeName,
        RANK() OVER (PARTITION BY P.Tags ORDER BY P.ViewCount DESC) AS TagRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Badges B ON U.Id = B.UserId AND B.Class = 1 
    WHERE 
        P.PostTypeId = 1 
        AND P.ViewCount > 1000 
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        C.Name AS Reason
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes C ON CAST(PH.Comment AS INT) = C.Id
    WHERE 
        PH.PostHistoryTypeId IN (10, 11) 
),
TopTaggedPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.OwnerDisplayName,
        RP.ViewCount,
        RP.BadgeName,
        CP.Reason,
        ROW_NUMBER() OVER (PARTITION BY RP.TagRank ORDER BY RP.ViewCount DESC) AS RowNum
    FROM 
        RankedPosts RP
    LEFT JOIN 
        ClosedPosts CP ON RP.PostId = CP.PostId
)
SELECT 
    TTP.Title,
    TTP.OwnerDisplayName,
    TTP.ViewCount,
    TTP.BadgeName,
    TTP.Reason
FROM 
    TopTaggedPosts TTP
WHERE 
    TTP.RowNum <= 5 
ORDER BY 
    TTP.ViewCount DESC;

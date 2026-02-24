
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        U.DisplayName AS OwnerDisplayName,
        COUNT(C.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS Rank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.PostTypeId = 1  
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score, U.DisplayName
),
FilteredPosts AS (
    SELECT 
        RP.PostId, 
        RP.Title, 
        RP.CreationDate, 
        RP.ViewCount, 
        RP.Score, 
        RP.OwnerDisplayName,
        FP.FieldName,
        FP.Value AS FieldValue
    FROM 
        RankedPosts RP
    LEFT JOIN (
        SELECT 
            P.Id AS PostId, 
            'Tags' AS FieldName, 
            P.Tags AS Value 
        FROM 
            Posts P 
        WHERE 
            P.PostTypeId = 1
        UNION ALL
        SELECT 
            P.Id AS PostId, 
            'AcceptedAnswerId' AS FieldName, 
            CAST(P.AcceptedAnswerId AS VARCHAR) AS Value 
        FROM 
            Posts P 
        WHERE 
            P.PostTypeId = 1
    ) FP ON RP.PostId = FP.PostId
    WHERE 
        RP.Rank <= 10  
)
SELECT 
    FP.OwnerDisplayName,
    FP.Title,
    FP.CreationDate,
    FP.ViewCount,
    FP.Score,
    STRING_AGG(FP.FieldName || ': ' || FP.FieldValue, '; ') AS AdditionalInfo
FROM 
    FilteredPosts FP
GROUP BY 
    FP.OwnerDisplayName, FP.Title, FP.CreationDate, FP.ViewCount, FP.Score
ORDER BY 
    FP.Score DESC;


WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY SUBSTRING(P.Tags, 2, LENGTH(P.Tags) - 2) ORDER BY P.CreationDate DESC) AS Rank,
        P.Tags
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1 
    AND 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
TagStatistics AS (
    SELECT 
        SUBSTRING(P.Tags, 2, LENGTH(P.Tags) - 2) AS Tag,
        COUNT(*) AS TagCount,
        SUM(P.Score) AS TotalScore,
        AVG(P.ViewCount) AS AverageViews
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        SUBSTRING(P.Tags, 2, LENGTH(P.Tags) - 2)
),
ClosedPostReasons AS (
    SELECT 
        PH.PostId,
        COUNT(*) AS CloseCount,
        MAX(PH.CreationDate) AS LastCloseDate,
        CT.Name AS CloseReason
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes CT ON PH.Comment = CAST(CT.Id AS VARCHAR)
    WHERE 
        PH.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        PH.PostId, CT.Name
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.Body,
    RP.CreationDate,
    RP.Score,
    RP.ViewCount,
    RP.OwnerDisplayName,
    TS.Tag,
    TS.TagCount,
    TS.TotalScore,
    TS.AverageViews,
    CPR.CloseCount,
    CPR.LastCloseDate,
    CPR.CloseReason
FROM 
    RankedPosts RP
LEFT JOIN 
    TagStatistics TS ON RP.Tags LIKE '%' || TS.Tag || '%' 
LEFT JOIN 
    ClosedPostReasons CPR ON RP.PostId = CPR.PostId 
WHERE 
    RP.Rank = 1 
ORDER BY 
    TS.TagCount DESC,
    RP.CreationDate DESC;

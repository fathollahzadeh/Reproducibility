WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COALESCE(U.DisplayName, 'Community User') AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.CreationDate ASC) AS Rank
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= '2022-01-01' AND 
        P.PostTypeId IN (1, 2) 
),
ClosedPosts AS (
    SELECT 
        PH.PostId, 
        PH.CreationDate AS ClosedDate,
        PH.UserId AS ClosedBy,
        CR.Name AS CloseReason
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes CR ON CR.Id = CAST(PH.Comment AS INT) 
    WHERE 
        PH.PostHistoryTypeId = 10  
),
PopularTags AS (
    SELECT 
        TagName,
        COUNT(*) AS TagCount
    FROM 
        Tags
    GROUP BY 
        TagName
    HAVING 
        COUNT(*) > 100
),
FilteredPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.CreationDate,
        RP.Score,
        RP.ViewCount,
        RP.OwnerDisplayName,
        CP.ClosedDate,
        CP.CloseReason,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = RP.PostId AND V.VoteTypeId = 2) AS UpVoteCount,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = RP.PostId AND V.VoteTypeId = 3) AS DownVoteCount,
        CASE 
            WHEN CP.ClosedDate IS NOT NULL THEN 'Closed'
            ELSE 'Open'
        END AS Status
    FROM 
        RankedPosts RP
    LEFT JOIN 
        ClosedPosts CP ON RP.PostId = CP.PostId
    WHERE 
        RP.Rank <= 10 
),
TagPostCounts AS (
    SELECT 
        P.Id AS PostId,
        ARRAY_AGG(T.TagName) AS AssociatedTags
    FROM 
        Posts P
    JOIN 
        Tags T ON POSITION('>' || T.TagName || '<' IN '<' || P.Tags || '>') > 0 
    GROUP BY 
        P.Id
)

SELECT 
    FP.PostId,
    FP.Title,
    FP.CreationDate,
    FP.Score,
    FP.ViewCount,
    FP.OwnerDisplayName,
    FP.ClosedDate,
    FP.CloseReason,
    FP.UpVoteCount,
    FP.DownVoteCount,
    FP.Status,
    COALESCE(TPC.AssociatedTags, '{}') AS Tags
FROM 
    FilteredPosts FP
LEFT JOIN 
    TagPostCounts TPC ON FP.PostId = TPC.PostId
WHERE 
    FP.Score > (SELECT AVG(Score) FROM FilteredPosts) 
ORDER BY 
    FP.Score DESC, FP.CreationDate DESC;
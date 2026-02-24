WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        U.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS ScoreRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
        AND P.ViewCount IS NOT NULL
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        ViewCount,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        ScoreRank <= 10
),
PostLinksCTE AS (
    SELECT 
        PL.PostId,
        COUNT(*) AS RelatedPostCount
    FROM 
        PostLinks PL
    WHERE 
        PL.LinkTypeId = 3
    GROUP BY 
        PL.PostId
),
FinalResults AS (
    SELECT 
        TP.PostId,
        TP.Title,
        TP.ViewCount,
        TP.OwnerDisplayName,
        COALESCE(PLC.RelatedPostCount, 0) AS RelatedPosts
    FROM 
        TopPosts TP
    LEFT JOIN 
        PostLinksCTE PLC ON TP.PostId = PLC.PostId
)
SELECT 
    FR.PostId,
    FR.Title,
    FR.ViewCount,
    FR.OwnerDisplayName,
    CASE 
        WHEN FR.RelatedPosts = 0 THEN 'No related posts'
        ELSE CONCAT(FR.RelatedPosts, ' related posts')
    END AS RelatedPostInfo
FROM 
    FinalResults FR
WHERE 
    FR.ViewCount > (SELECT AVG(ViewCount) FROM FinalResults) 
ORDER BY 
    FR.ViewCount DESC
LIMIT 20;
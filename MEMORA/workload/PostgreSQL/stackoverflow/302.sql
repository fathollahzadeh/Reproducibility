WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpvoteCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownvoteCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS OwnerPostRank
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
        AND P.Score > 0
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, U.DisplayName, P.OwnerUserId
),
EnhancedHistory AS (
    SELECT 
        PH.Id AS HistoryId,
        PH.PostId,
        PH.CreationDate,
        PH.Comment,
        P.Title AS PostTitle,
        P.OwnerUserId,
        PH.PostHistoryTypeId,
        COALESCE((
            SELECT 
                COUNT(*) 
            FROM 
                Comments C 
            WHERE 
                C.PostId = PH.PostId
        ), 0) AS CommentCount
    FROM 
        PostHistory PH
    JOIN 
        Posts P ON PH.PostId = P.Id
    WHERE 
        PH.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '6 months'
        AND PH.PostHistoryTypeId IN (10, 11)
),
FinalReport AS (
    SELECT 
        R.OwnerDisplayName,
        R.Title AS PostTitle,
        R.Score AS PostScore,
        R.ViewCount,
        E.HistoryId,
        E.Comment,
        E.PostHistoryTypeId,
        R.OwnerPostRank
    FROM 
        RankedPosts R
    FULL OUTER JOIN 
        EnhancedHistory E ON R.PostId = E.PostId
    WHERE 
        R.OwnerPostRank <= 5 OR E.HistoryId IS NOT NULL
)
SELECT 
    OwnerDisplayName,
    PostTitle,
    PostScore,
    ViewCount,
    HistoryId,
    Comment,
    CASE 
        WHEN PostHistoryTypeId IS NULL THEN 'N/A'
        ELSE (SELECT Name FROM PostHistoryTypes WHERE Id = PostHistoryTypeId)
    END AS ChangeType
FROM 
    FinalReport
ORDER BY 
    PostScore DESC, OwnerDisplayName;
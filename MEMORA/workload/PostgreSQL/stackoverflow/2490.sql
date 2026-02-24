WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        U.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
RecentComments AS (
    SELECT 
        C.PostId, 
        COUNT(*) AS CommentCount, 
        MAX(C.CreationDate) AS LastCommentDate
    FROM 
        Comments C
    WHERE 
        C.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 month'
    GROUP BY 
        C.PostId
),
PostAggregation AS (
    SELECT 
        RP.PostId, 
        RP.Title, 
        RP.CreationDate, 
        RP.Score, 
        RP.ViewCount, 
        RP.OwnerDisplayName,
        COALESCE(RC.CommentCount, 0) AS CommentCount,
        RC.LastCommentDate
    FROM 
        RankedPosts RP
    LEFT JOIN 
        RecentComments RC ON RP.PostId = RC.PostId
    WHERE 
        RP.PostRank <= 5
)
SELECT 
    PA.PostId, 
    PA.Title,
    PA.OwnerDisplayName,
    PA.CreationDate,
    PA.Score,
    PA.ViewCount,
    PA.CommentCount,
    CASE 
        WHEN PA.CommentCount > 0 THEN 'Active'
        ELSE 'Inactive'
    END AS PostActivity,
    (SELECT 
        COUNT(*) 
     FROM 
        Votes V 
     WHERE 
        V.PostId = PA.PostId 
        AND V.VoteTypeId = 2) AS UpvoteCount,
    (SELECT 
        COUNT(*) 
     FROM 
        Votes V 
     WHERE 
        V.PostId = PA.PostId 
        AND V.VoteTypeId = 3) AS DownvoteCount
FROM 
    PostAggregation PA
ORDER BY 
    PA.Score DESC, PA.CommentCount DESC;

WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        DENSE_RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS ScoreRank,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.CreationDate DESC) AS RecentRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),

PostMetrics AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        OwnerDisplayName,
        Score,
        ViewCount,
        ScoreRank,
        RecentRank,
        COALESCE((SELECT COUNT(*) FROM Comments C WHERE C.PostId = R.PostId), 0) AS CommentCount,
        COALESCE((SELECT COUNT(*) FROM Votes V WHERE V.PostId = R.PostId AND V.VoteTypeId = 2), 0) AS UpVotes
    FROM 
        RankedPosts R
),

HighScorePosts AS (
    SELECT 
        PostId,
        Title,
        OwnerDisplayName,
        Score,
        ViewCount,
        CommentCount,
        UpVotes,
        CASE 
            WHEN ScoreRank = 1 THEN 'Top Scoring'
            WHEN ScoreRank <= 5 THEN 'High Scoring'
            ELSE 'Moderate Scoring'
        END AS ScoreCategory
    FROM 
        PostMetrics
    WHERE 
        Score > 10
),

ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        PH.UserDisplayName,
        PH.Comment,
        PH.Text AS ClosureReason,
        P.Title AS ClosedPostTitle
    FROM 
        PostHistory PH
    JOIN 
        Posts P ON PH.PostId = P.Id
    WHERE 
        PH.PostHistoryTypeId = 10
),

ScoreAnalysis AS (
    SELECT 
        H.PostId,
        H.Title,
        H.OwnerDisplayName,
        H.Score,
        H.CommentCount,
        H.UpVotes,
        C.CreationDate AS ClosedDate,
        C.UserDisplayName AS Closer,
        C.ClosureReason
    FROM 
        HighScorePosts H
    LEFT JOIN 
        ClosedPosts C ON H.PostId = C.PostId
)

SELECT 
    PostId,
    Title,
    OwnerDisplayName,
    Score,
    CommentCount,
    UpVotes,
    CASE 
        WHEN ClosedDate IS NOT NULL THEN 'Closed Post'
        ELSE 'Open Post'
    END AS PostStatus,
    COALESCE(CAST(ClosedDate AS DATE), CAST('2024-10-01 12:34:56' AS DATE)) AS ClosureDateOrCurrentDate,
    COALESCE(Closer, 'N/A') AS CloserName,
    COALESCE(ClosureReason, 'Not Applicable') AS ClosureReason
FROM 
    ScoreAnalysis
WHERE 
    (Score > 20 OR CommentCount > 10)
    AND (CASE 
            WHEN ClosedDate IS NOT NULL THEN 'Closed Post'
            ELSE 'Open Post'
          END = 'Open Post' 
         OR (CASE 
                WHEN ClosedDate IS NOT NULL THEN 'Closed Post'
                ELSE 'Open Post'
              END = 'Closed Post' AND UpVotes > 5))
ORDER BY 
    Score DESC, CommentCount DESC
LIMIT 50;

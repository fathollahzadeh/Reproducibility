
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
),
FilteredPosts AS (
    SELECT 
        rp.*,
        ph.PostHistoryTypeId,
        ph.CreationDate AS HistoryCreationDate,
        ROW_NUMBER() OVER (PARTITION BY rp.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM RankedPosts rp
    LEFT JOIN PostHistory ph ON rp.PostId = ph.PostId
    WHERE ph.PostHistoryTypeId IN (10, 11, 12)  
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        OwnerDisplayName,
        ViewCount,
        Score
    FROM FilteredPosts
    WHERE ScoreRank <= 10  
    AND UserPostRank = 1   
),
PostStats AS (
    SELECT 
        tp.PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,  
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount  
    FROM TopPosts tp
    LEFT JOIN Comments c ON tp.PostId = c.PostId
    LEFT JOIN Votes v ON tp.PostId = v.PostId
    GROUP BY tp.PostId
),
FinalOutput AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.OwnerDisplayName,
        tp.ViewCount,
        tp.Score,
        ps.CommentCount,
        ps.UpvoteCount,
        ps.DownvoteCount,
        CASE 
            WHEN ps.UpvoteCount IS NULL THEN 'No Upvotes' 
            WHEN ps.UpvoteCount = 0 THEN 'Zero Upvotes' 
            ELSE 'Has Upvotes' 
        END AS UpvoteStatus,
        CASE 
            WHEN ps.DownvoteCount IS NULL THEN 'No Downvotes' 
            WHEN ps.DownvoteCount = 0 THEN 'Zero Downvotes' 
            ELSE 'Has Downvotes' 
        END AS DownvoteStatus
    FROM TopPosts tp
    LEFT JOIN PostStats ps ON tp.PostId = ps.PostId
)
SELECT 
    PostId,
    Title,
    OwnerDisplayName,
    ViewCount,
    Score,
    CommentCount,
    UpvoteCount,
    DownvoteCount,
    UpvoteStatus,
    DownvoteStatus
FROM FinalOutput
WHERE Score > 0  
ORDER BY Score DESC, CommentCount DESC
LIMIT 50;

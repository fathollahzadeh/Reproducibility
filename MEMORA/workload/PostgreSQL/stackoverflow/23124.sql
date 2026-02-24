
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        u.DisplayName AS OwnerDisplayName,
        CASE 
            WHEN rp.ViewCount = 0 THEN 'No views'
            WHEN rp.ViewCount > 100 THEN 'High views'
            ELSE 'Moderate views'
        END AS ViewCategory
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    WHERE 
        rp.PostRank <= 5
),
PostStats AS (
    SELECT 
        fp.PostId,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvoteCount,
        fp.ViewCategory,
        MIN(ph.CreationDate) AS FirstHistoryDate,
        MAX(ph.CreationDate) AS LastHistoryDate
    FROM 
        FilteredPosts fp
    LEFT JOIN 
        Comments c ON c.PostId = fp.PostId
    LEFT JOIN 
        Votes v ON v.PostId = fp.PostId
    LEFT JOIN 
        PostHistory ph ON ph.PostId = fp.PostId
    GROUP BY 
        fp.PostId, fp.ViewCategory
),
FinalResults AS (
    SELECT 
        s.PostId,
        fp.Title,
        fp.CreationDate,
        fp.ViewCount,
        s.CommentCount,
        s.UpvoteCount,
        s.DownvoteCount,
        s.ViewCategory,
        CASE 
            WHEN s.CommentCount > 0 THEN 'Commented'
            ELSE 'Not commented'
        END AS CommentStatus,
        CASE 
            WHEN s.FirstHistoryDate IS NULL THEN 'No history'
            ELSE 'Has history'
        END AS HistoryStatus,
        EXTRACT(YEAR FROM AGE(s.FirstHistoryDate)) AS YearsSinceFirstHistory
    FROM 
        PostStats s
    JOIN 
        FilteredPosts fp ON s.PostId = fp.PostId
)
SELECT 
    PostId,
    Title,
    CreationDate,
    ViewCount,
    CommentCount,
    UpvoteCount,
    DownvoteCount,
    ViewCategory,
    CommentStatus,
    HistoryStatus,
    YearsSinceFirstHistory
FROM 
    FinalResults
WHERE 
    YearsSinceFirstHistory > 2 
ORDER BY 
    UpvoteCount DESC, 
    ViewCount DESC
LIMIT 50;

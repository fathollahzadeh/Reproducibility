
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS Owner,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, u.DisplayName, p.OwnerUserId, p.CreationDate
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Owner,
        rp.CommentCount,
        rp.UpvoteCount,
        rp.DownvoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1
        AND rp.UpvoteCount > rp.DownvoteCount
),
PostHistoryInfo AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate AS HistoryDate,
        pht.Name AS ChangeType,
        ph.Comment
    FROM 
        PostHistory ph
    JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.PostId IN (SELECT PostId FROM FilteredPosts)
)
SELECT 
    fp.Title,
    fp.CreationDate,
    fp.Owner,
    fp.CommentCount,
    fp.UpvoteCount,
    fp.DownvoteCount,
    STRING_AGG(DISTINCT CONCAT('Changed by ', (SELECT DisplayName FROM Users WHERE Id = phi.UserId), ' on ', CAST(phi.HistoryDate AS VARCHAR)), '; ') AS ChangeDetails
FROM 
    FilteredPosts fp
LEFT JOIN PostHistoryInfo phi ON fp.PostId = phi.PostId
GROUP BY 
    fp.PostId, fp.Title, fp.CreationDate, fp.Owner, fp.CommentCount, fp.UpvoteCount, fp.DownvoteCount
ORDER BY 
    fp.UpvoteCount DESC, fp.CommentCount DESC;

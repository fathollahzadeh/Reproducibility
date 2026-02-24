
WITH RecursivePostHistory AS (
    SELECT 
        ph.PostId, 
        ph.UserId, 
        ph.CreationDate, 
        ph.Comment, 
        ph.PostHistoryTypeId, 
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS RecentEdit
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (10, 11) 
), PostSummaries AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate AS PostCreationDate,
        p.Score, 
        p.ViewCount, 
        p.AnswerCount,
        p.OwnerUserId, 
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpvoteCount
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, p.OwnerUserId, u.DisplayName
), ActiveTags AS (
    SELECT 
        t.TagName, 
        COUNT(pt.Id) AS PostCount
    FROM Tags t
    JOIN Posts pt ON pt.Tags LIKE '%' || t.TagName || '%'
    GROUP BY t.TagName
    HAVING COUNT(pt.Id) > 0
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.PostCreationDate,
    ps.Score,
    ps.ViewCount,
    ps.AnswerCount,
    ps.OwnerDisplayName,
    ps.CommentCount,
    ps.UpvoteCount,
    r.RecentEdit AS RecentEdit,
    CASE 
        WHEN r.PostHistoryTypeId = 10 THEN 'Closed'
        WHEN r.PostHistoryTypeId = 11 THEN 'Reopened'
        ELSE 'N/A'
    END AS CurrentState,
    COALESCE(tt.TagNames, 'No Tags') AS AssociatedTags
FROM PostSummaries ps
LEFT JOIN RecursivePostHistory r ON ps.PostId = r.PostId AND r.RecentEdit = 1
LEFT JOIN (
    SELECT 
        pt.Id AS PostId, 
        STRING_AGG(t.TagName, ', ') AS TagNames
    FROM Posts pt
    JOIN Tags t ON pt.Tags LIKE '%' || t.TagName || '%'
    GROUP BY pt.Id
) tt ON ps.PostId = tt.PostId
WHERE ps.Score > 0
ORDER BY ps.ViewCount DESC, ps.Score DESC;

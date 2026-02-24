
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.PostTypeId,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvoteCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(pl.Id) AS LinkCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostLinks pl ON p.Id = pl.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.PostTypeId, u.DisplayName
),

PostHistoryResult AS (
    SELECT 
        ph.PostId, 
        MAX(ph.CreationDate) AS LastEditDate, 
        MAX(CASE WHEN ph.PostHistoryTypeId = 4 THEN ph.CreationDate END) AS LastTitleEditDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS LastClosedDate,
        STRING_AGG(ph.Comment, '; ') AS EditComments
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),

RankedPosts AS (
    SELECT 
        rp.*,
        ph.LastEditDate,
        ph.LastTitleEditDate,
        ph.LastClosedDate,
        ph.EditComments,
        ROW_NUMBER() OVER (ORDER BY rp.UpvoteCount DESC, rp.CommentCount DESC, rp.CreationDate DESC) AS Rank
    FROM 
        RecentPosts rp
    LEFT JOIN 
        PostHistoryResult ph ON rp.PostId = ph.PostId
)

SELECT 
    r.PostId,
    r.Title,
    r.OwnerDisplayName,
    r.UpvoteCount,
    r.DownvoteCount,
    r.CommentCount,
    r.LinkCount,
    r.LastEditDate,
    r.LastTitleEditDate,
    r.LastClosedDate,
    r.EditComments,
    CASE 
        WHEN r.LastClosedDate IS NOT NULL THEN 'Closed'
        WHEN r.UpvoteCount = 0 AND r.CommentCount = 0 THEN 'Inactive'
        ELSE 'Active'
    END AS PostStatus
FROM 
    RankedPosts r
WHERE 
    r.Rank <= 100
ORDER BY 
    r.Rank;

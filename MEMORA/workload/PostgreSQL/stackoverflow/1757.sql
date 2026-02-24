WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
        LEFT JOIN Users u ON p.OwnerUserId = u.Id
        LEFT JOIN Votes v ON p.Id = v.PostId
        LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, u.DisplayName
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.UserId,
        ph.Comment,
        ph.Text AS CloseReason
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
),
OpenPosts AS (
    SELECT 
        rp.*,
        CASE 
            WHEN cp.PostId IS NULL THEN 'Open'
            ELSE 'Closed'
        END AS PostStatus
    FROM 
        RankedPosts rp
        LEFT JOIN ClosedPosts cp ON rp.PostId = cp.PostId
)
SELECT 
    op.PostId,
    op.Title,
    op.CreationDate,
    op.OwnerDisplayName,
    op.UpVotes,
    op.DownVotes,
    op.CommentCount,
    op.PostStatus,
    ROW_NUMBER() OVER (ORDER BY op.UpVotes DESC, op.CreationDate ASC) AS GlobalRank
FROM 
    OpenPosts op
WHERE 
    op.PostRank <= 5
ORDER BY 
    op.OwnerDisplayName, op.UpVotes DESC;
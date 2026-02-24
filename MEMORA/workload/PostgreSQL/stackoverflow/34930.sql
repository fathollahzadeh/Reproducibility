WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.CommentCount,
        rp.UpVoteCount,
        rp.DownVoteCount,
        CASE 
            WHEN rp.CommentCount > 10 THEN 'Highly Discussed'
            WHEN rp.UpVoteCount > 50 THEN 'Popular'
            ELSE 'Normal'
        END AS PostCategory
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1
),
OpenCloseHistory AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS history_rn
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
)
SELECT 
    tp.Title AS PostTitle,
    tp.CreationDate AS PostCreationDate,
    tp.ViewCount AS TotalViews,
    tp.Score AS TotalScore,
    tp.CommentCount AS TotalComments,
    tp.UpVoteCount AS TotalUpVotes,
    tp.DownVoteCount AS TotalDownVotes,
    COALESCE(och.CreationDate, tp.CreationDate) AS LastActivityDate,
    tp.PostCategory,
    CASE 
        WHEN och.PostId IS NOT NULL THEN 
            CASE WHEN och.PostHistoryTypeId = 10 THEN 'Closed'
                 WHEN och.PostHistoryTypeId = 11 THEN 'Reopened'
            END
        ELSE 'Active'
    END AS PostStatus
FROM 
    TopPosts tp
LEFT JOIN 
    OpenCloseHistory och ON tp.Id = och.PostId AND och.history_rn = 1
WHERE 
    tp.ViewCount > 100 
ORDER BY 
    tp.ViewCount DESC,
    tp.Score DESC
LIMIT 50;
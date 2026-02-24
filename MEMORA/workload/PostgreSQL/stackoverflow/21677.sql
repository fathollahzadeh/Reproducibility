
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3), 0) AS DownVotes
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames,
        COUNT(*) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostCommentCount AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.PostId
),
FinalPostData AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.UpVotes,
        rp.DownVotes,
        COALESCE(pcc.CommentCount, 0) AS CommentCount,
        COALESCE(cp.CloseCount, 0) AS CloseCount,
        ub.BadgeNames
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostCommentCount pcc ON rp.PostId = pcc.PostId
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
    LEFT JOIN 
        UserBadges ub ON rp.PostId IN (SELECT pr.AcceptedAnswerId FROM Posts pr WHERE pr.Id = rp.PostId)
    WHERE 
        rp.Rank <= 5
)
SELECT 
    f.PostId,
    f.Title,
    f.CreationDate,
    f.Score,
    f.ViewCount,
    f.CommentCount,
    f.CloseCount,
    f.BadgeNames,
    CASE 
        WHEN f.CloseCount > 0 THEN 'Closed'
        WHEN f.UpVotes - f.DownVotes > 0 THEN 'Popular'
        ELSE 'Unpopular'
    END AS PostStatus
FROM 
    FinalPostData f
WHERE 
    f.Score > 10
ORDER BY 
    f.Score DESC, 
    f.UpVotes DESC;

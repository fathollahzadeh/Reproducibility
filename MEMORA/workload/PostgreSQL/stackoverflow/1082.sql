WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '6 months'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.OwnerUserId
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        CASE 
            WHEN rp.UpVotes IS NULL THEN 0 
            ELSE rp.UpVotes 
        END AS UpvoteCount,
        CASE 
            WHEN rp.DownVotes IS NULL THEN 0 
            ELSE rp.DownVotes 
        END AS DownvoteCount,
        CASE 
            WHEN rp.Score >= 0 THEN 'Positive' 
            ELSE 'Negative' 
        END AS ScoreCategory
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn <= 3
),
CombinedPosts AS (
    SELECT 
        fp.PostId,
        fp.Title,
        fp.CreationDate,
        fp.ViewCount,
        fp.Score,
        fp.CommentCount,
        fp.UpvoteCount,
        fp.DownvoteCount,
        fp.ScoreCategory
    FROM 
        FilteredPosts fp
    UNION ALL
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpvoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownvoteCount,
        CASE 
            WHEN p.Score >= 0 THEN 'Positive' 
            ELSE 'Negative' 
        END AS ScoreCategory
    FROM 
        Posts p
    WHERE 
        p.CreationDate <= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '6 months'
)
SELECT 
    cb.*,
    COALESCE(u.DisplayName, 'Anonymous') AS OwnerName
FROM 
    CombinedPosts cb
LEFT JOIN 
    Users u ON cb.PostId = u.Id
WHERE 
    cb.CommentCount > 0
ORDER BY 
    cb.ViewCount DESC
LIMIT 50;
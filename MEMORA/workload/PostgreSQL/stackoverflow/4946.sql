WITH PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVoteCount,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadgeCount,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadgeCount,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadgeCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        p.Id
), RankedPosts AS (
    SELECT 
        pm.*, 
        RANK() OVER (ORDER BY (UpVoteCount - DownVoteCount) DESC, CreationDate DESC) AS PostRank
    FROM 
        PostMetrics pm
), FilteredPosts AS (
    SELECT 
        *,
        CASE 
            WHEN Title ILIKE '%SQL%' THEN 'SQL Post'
            ELSE 'Other Post'
        END AS PostType
    FROM 
        RankedPosts
    WHERE 
        CommentCount > 5
    AND 
        PostRank <= 20
)
SELECT 
    fp.PostId, 
    fp.Title, 
    fp.CreationDate, 
    fp.CommentCount, 
    fp.UpVoteCount, 
    fp.DownVoteCount,
    fp.GoldBadgeCount,
    fp.SilverBadgeCount,
    fp.BronzeBadgeCount,
    fp.PostType,
    (SELECT COUNT(*) FROM Votes v2 WHERE v2.PostId = fp.PostId AND v2.VoteTypeId = 10) AS DeletionVotes
FROM 
    FilteredPosts fp
ORDER BY 
    fp.PostRank;
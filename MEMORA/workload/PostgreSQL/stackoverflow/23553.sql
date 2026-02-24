WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS ViewRank,
        DENSE_RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserUpvoteStatistics AS (
    SELECT 
        u.Id AS UserId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
PostsWithBadges AS (
    SELECT 
        p.Id,
        p.Title,
        b.Name AS BadgeName,
        p.OwnerUserId,
        COALESCE(b.Class, 0) AS BadgeClass
    FROM 
        Posts p
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId AND b.Date >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '6 months'
),
PostInteraction AS (
    SELECT 
        ph.PostId,
        p.OwnerUserId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        MAX(ph.CreationDate) AS LastHistoryDate
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON p.Id = ph.PostId
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    GROUP BY 
        ph.PostId, p.OwnerUserId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    ust.UpVotes,
    ust.DownVotes,
    w.BadgeName,
    w.BadgeClass,
    pi.CommentCount,
    pi.VoteCount,
    pi.LastHistoryDate
FROM 
    RankedPosts rp
LEFT JOIN 
    UserUpvoteStatistics ust ON rp.PostId = ust.UserId
LEFT JOIN 
    PostsWithBadges w ON rp.PostId = w.Id
LEFT JOIN 
    PostInteraction pi ON rp.PostId = pi.PostId
WHERE 
    rp.ViewRank <= 10
    AND (ust.UpVotes IS NULL OR ust.UpVotes > ust.DownVotes)
ORDER BY 
    rp.ViewCount DESC, 
    rp.CreationDate DESC
LIMIT 50;
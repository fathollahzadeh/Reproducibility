
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
PostsWithComments AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.UpVotes,
        rp.DownVotes,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        rp.OwnerUserId
    FROM 
        RankedPosts rp
    LEFT JOIN 
        (SELECT 
            PostId, 
            COUNT(*) AS CommentCount 
         FROM 
            Comments 
         GROUP BY 
            PostId) c ON rp.PostId = c.PostId
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        ARRAY_AGG(DISTINCT b.Name) AS BadgeNames,
        COUNT(DISTINCT b.Class) AS BadgeLevelCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostHistoryGrouping AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        CASE 
            WHEN ph.PostHistoryTypeId = 10 THEN 'Close'
            WHEN ph.PostHistoryTypeId = 11 THEN 'Reopen'
            ELSE 'Other'
        END AS ActionType,
        COUNT(*) AS ActionCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
)
SELECT 
    wp.Title,
    wp.CreationDate,
    wp.Score,
    wp.UpVotes,
    wp.DownVotes,
    wp.CommentCount,
    ub.BadgeNames,
    phg.ActionType,
    phg.ActionCount
FROM 
    PostsWithComments wp
LEFT JOIN 
    UserBadges ub ON wp.OwnerUserId = ub.UserId
LEFT JOIN 
    PostHistoryGrouping phg ON wp.PostId = phg.PostId
WHERE 
    wp.CommentCount > 5 
    AND EXISTS (
        SELECT 1 
        FROM Votes v 
        WHERE v.PostId = wp.PostId AND v.UserId IN (SELECT UserId FROM Users WHERE Reputation > 1000)
    )
ORDER BY 
    wp.Score DESC, wp.CreationDate ASC
LIMIT 50;

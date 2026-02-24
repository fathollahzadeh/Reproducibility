WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
UserActivity AS (
    SELECT
        u.Id AS UserId,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COUNT(DISTINCT ph.Id) AS EditCount,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        ua.Upvotes,
        ua.Downvotes,
        ua.EditCount,
        ua.CommentCount,
        RANK() OVER (ORDER BY ua.Upvotes - ua.Downvotes DESC, ua.EditCount DESC) AS ActivityRank
    FROM 
        Users u
    JOIN 
        UserActivity ua ON u.Id = ua.UserId
    WHERE 
        u.Reputation > 1000
)
SELECT 
    r.PostId,
    r.Title,
    u.DisplayName,
    r.CreationDate,
    r.Score,
    r.ViewCount,
    COALESCE(ua.Upvotes, 0) AS UserUpvotes,
    COALESCE(ua.Downvotes, 0) AS UserDownvotes,
    COALESCE(ua.EditCount, 0) AS UserEditCount,
    COALESCE(ua.CommentCount, 0) AS UserCommentCount,
    CASE 
        WHEN r.Rank = 1 THEN 'Most Recent'
        ELSE 'Other'
    END AS PostStatus
FROM 
    RankedPosts r
JOIN 
    Users u ON r.OwnerUserId = u.Id
LEFT JOIN 
    UserActivity ua ON u.Id = ua.UserId
WHERE 
    r.Rank <= 5 
ORDER BY 
    r.CreationDate DESC;
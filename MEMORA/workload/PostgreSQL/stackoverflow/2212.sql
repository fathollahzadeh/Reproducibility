WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.OwnerUserId, 
        p.Score, 
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
        AND p.PostTypeId = 1
),
UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.Reputation, 
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes
    FROM 
        Users u 
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostStatistics AS (
    SELECT 
        p.PostId,
        COUNT(c.Id) AS CommentCount, 
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(COALESCE(ph.UserId, 0)) AS HistoryCount
    FROM 
        RankedPosts p
    LEFT JOIN 
        Comments c ON p.PostId = c.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    LEFT JOIN 
        PostHistory ph ON p.PostId = ph.PostId
    WHERE 
        p.rn = 1 
    GROUP BY 
        p.PostId
)
SELECT 
    ps.PostId,
    ps.CommentCount,
    ps.BadgeCount,
    ur.Reputation,
    ur.Upvotes,
    ur.Downvotes,
    COALESCE((
        SELECT STRING_AGG(DISTINCT tt.TagName, ', ')
        FROM Tags tt
        JOIN Posts tp ON tp.Tags LIKE CONCAT('%', tt.TagName, '%')
        WHERE tp.Id = ps.PostId
    ), 'No Tags') AS Tags
FROM 
    PostStatistics ps
JOIN 
    UserReputation ur ON ps.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = ur.UserId)
WHERE 
    ur.Reputation > 500
ORDER BY 
    ps.CommentCount DESC, ur.Reputation DESC
LIMIT 10;
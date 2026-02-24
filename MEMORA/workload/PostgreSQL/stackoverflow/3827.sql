
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title, 
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS ClosedCount,
        MAX(ph.CreationDate) AS LastEditedDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id, p.Title
)
SELECT 
    us.DisplayName,
    us.UpVotes,
    us.DownVotes,
    ps.Title AS RecentPostTitle,
    ps.CreationDate,
    pd.CommentCount,
    pd.ClosedCount,
    pd.LastEditedDate
FROM 
    UserStats us
LEFT JOIN 
    RankedPosts ps ON us.UserId = ps.OwnerUserId AND ps.PostRank = 1
LEFT JOIN 
    PostDetails pd ON ps.Id = pd.PostId
WHERE 
    us.UpVotes > 10 
    OR (us.BadgeCount > 5 AND pd.ClosedCount = 0)
ORDER BY 
    us.UpVotes DESC, 
    us.DownVotes ASC
LIMIT 10;

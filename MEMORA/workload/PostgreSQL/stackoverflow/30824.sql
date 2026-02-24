
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
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
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
UsersWithBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopContributors AS (
    SELECT 
        u.DisplayName,
        SUM(rp.UpVotes - rp.DownVotes) AS NetVotes,
        COUNT(rp.PostId) AS TotalPosts
    FROM 
        UsersWithBadges uwb
    JOIN 
        RecentPosts rp ON uwb.UserId = rp.OwnerUserId
    JOIN 
        Users u ON uwb.UserId = u.Id
    GROUP BY 
        u.DisplayName
    ORDER BY 
        NetVotes DESC
    LIMIT 5
),
PostHistoryChanges AS (
    SELECT 
        ph.PostId,
        p.Title,
        ph.CreationDate,
        ph.UserDisplayName,
        ph.Comment,
        ph.UserId,
        p.ViewCount,
        pt.Name AS PostHistoryType
    FROM 
        PostHistory ph
    INNER JOIN 
        Posts p ON ph.PostId = p.Id
    LEFT JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE 
        ph.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '60 days'
)
SELECT 
    p.Title AS PostTitle,
    p.CreationDate AS PostCreationDate,
    u.DisplayName AS PostOwner,
    ph.UserDisplayName AS LastEditedBy,
    ph.CreationDate AS LastEditDate,
    ph.Comment AS EditComment,
    ph.PostHistoryType AS ChangeType,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes
FROM 
    RecentPosts rp
JOIN 
    Posts p ON rp.PostId = p.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    PostHistoryChanges ph ON rp.PostId = ph.PostId
WHERE 
    rp.CommentCount > 0
    OR (rp.UpVotes - rp.DownVotes) > 0
ORDER BY 
    rp.CreationDate DESC
LIMIT 
    10;

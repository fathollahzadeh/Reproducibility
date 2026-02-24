
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        CASE 
            WHEN COUNT(DISTINCT p.Id) > 10 THEN 'Active'
            ELSE 'Inactive'
        END AS UserActivityStatus,
        COALESCE(SUM(b.Class), 0) AS TotalBadges,
        COUNT(DISTINCT ph.Id) AS PostHistoryCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.CreationDate
),
DetailedPostInfo AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        us.DisplayName AS OwnerDisplayName,
        us.UserActivityStatus,
        CASE 
            WHEN rp.CommentCount IS NULL THEN 'No Comments'
            ELSE 'Has Comments'
        END AS CommentStatus
    FROM 
        RankedPosts rp
    JOIN 
        UserStats us ON rp.OwnerUserId = us.UserId
    WHERE 
        rp.PostRank = 1
)
SELECT 
    dpi.PostId,
    dpi.Title,
    dpi.CommentCount,
    dpi.UpVotes,
    dpi.DownVotes,
    dpi.OwnerDisplayName,
    dpi.UserActivityStatus,
    dpi.CommentStatus,
    COALESCE((SELECT STRING_AGG(h.Comment, ', ') 
               FROM PostHistory h 
               WHERE h.PostId = dpi.PostId 
                 AND h.PostHistoryTypeId IN (4, 5)), 'No Edits') AS RecentEdits
FROM 
    DetailedPostInfo dpi
ORDER BY 
    dpi.UpVotes DESC, dpi.CommentCount DESC;


WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS DownVotes,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
),
BadgedUsers AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Date) AS LatestBadgeDate
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
RecentActiveUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.LastAccessDate DESC) AS RecentActivityRank
    FROM 
        Users u
    WHERE 
        u.LastAccessDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days')
)
SELECT 
    ps.Title AS PostTitle,
    ps.CreationDate AS PostCreationDate,
    ps.ViewCount AS PostViewCount,
    ps.UpVotes AS PostUpVotes,
    ps.DownVotes AS PostDownVotes,
    ps.CommentCount AS PostCommentCount,
    bu.BadgeCount AS UserBadgeCount,
    rau.DisplayName AS RecentActiveUserDisplayName,
    CASE 
        WHEN ps.RecentPostRank <= 10 THEN 'Recent Top 10 Questions'
        ELSE 'Older Questions'
    END AS PostCategory,
    COALESCE(rau.RecentActivityRank, 0) AS UserActivityRank
FROM 
    PostStats ps
FULL OUTER JOIN 
    BadgedUsers bu ON ps.PostId = bu.UserId
FULL OUTER JOIN 
    RecentActiveUsers rau ON bu.UserId = rau.Id
WHERE 
    (ps.UpVotes - ps.DownVotes) > 0 
    AND (COALESCE(bu.BadgeCount, 0) > 2 OR COALESCE(rau.Reputation, 0) > 100) 
ORDER BY 
    ps.CreationDate DESC, COALESCE(bu.BadgeCount, 0) DESC, COALESCE(rau.Reputation, 0) DESC;

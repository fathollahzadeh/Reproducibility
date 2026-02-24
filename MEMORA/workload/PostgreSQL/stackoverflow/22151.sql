WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON c.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
ActiveUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.UpVotes,
        us.DownVotes,
        us.PostCount,
        us.CommentCount,
        rp.PostId
    FROM 
        UserStats us
    JOIN 
        RecentPosts rp ON us.UserId = rp.OwnerUserId
    WHERE 
        us.PostCount > 0
)
SELECT 
    au.DisplayName,
    au.UpVotes,
    au.DownVotes,
    au.PostCount,
    au.CommentCount,
    COALESCE(ph.Comment, 'No comments') AS LastPostComment,
    COALESCE(pl.RelatedPostId, -1) AS RelatedPost,
    CASE 
        WHEN au.PostCount > 10 THEN 'Prolific Author'
        WHEN au.PostCount BETWEEN 5 AND 10 THEN 'Moderately Active'
        ELSE 'Newbie'
    END AS ActivityLevel
FROM 
    ActiveUsers au
LEFT JOIN 
    PostHistory ph ON ph.UserId = au.UserId AND ph.PostId IN (SELECT p.PostId FROM RecentPosts p WHERE p.RecentRank = 1)
LEFT JOIN 
    PostLinks pl ON pl.PostId = au.PostId
ORDER BY 
    au.UpVotes DESC, au.PostCount DESC, au.CommentCount DESC
LIMIT 100;
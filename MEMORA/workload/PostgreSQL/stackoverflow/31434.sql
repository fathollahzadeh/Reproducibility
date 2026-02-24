WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        ph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.ParentId = ph.PostId
), 
PostVoteCount AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostDetails AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(ph.Level, -1) AS Level, 
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes,
        COALESCE(u.BadgeCount, 0) AS BadgeCount,
        COALESCE(u.BadgeNames, 'No Badges') AS BadgeNames
    FROM 
        Posts p
    LEFT JOIN 
        PostVoteCount v ON p.Id = v.PostId
    LEFT JOIN 
        UserBadges u ON p.OwnerUserId = u.UserId
    LEFT JOIN 
        PostHierarchy ph ON p.Id = ph.PostId
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.Level,
    pd.UpVotes,
    pd.DownVotes,
    pd.BadgeCount,
    pd.BadgeNames,
    CASE 
        WHEN pd.UpVotes > pd.DownVotes THEN 'More UpVotes'
        WHEN pd.UpVotes < pd.DownVotes THEN 'More DownVotes'
        ELSE 'Equal Votes'
    END AS VoteStatus
FROM 
    PostDetails pd
WHERE 
    pd.Level >= 0 
ORDER BY 
    pd.CreationDate DESC
LIMIT 100;
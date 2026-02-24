WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS TotalBadges,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        COUNT(c.Id) AS CommentsCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.PostTypeId
),
PostData AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.PostTypeId,
        ps.CommentsCount,
        ps.UpVotes,
        ps.DownVotes,
        u.DisplayName AS OwnerDisplayName,
        ub.TotalBadges,
        ub.BadgeNames
    FROM 
        PostStatistics ps
    JOIN 
        Posts p ON ps.PostId = p.Id
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    WHERE 
        ps.CommentsCount > 5 AND ps.UpVotes > ps.DownVotes
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.OwnerDisplayName,
    pd.TotalBadges,
    pd.BadgeNames,
    pd.CommentsCount,
    pd.UpVotes,
    pd.DownVotes,
    CASE 
        WHEN pd.PostTypeId = 1 THEN 'Question'
        WHEN pd.PostTypeId = 2 THEN 'Answer'
        ELSE 'Other'
    END AS PostTypeLabel
FROM 
    PostData pd
ORDER BY 
    pd.CommentsCount DESC, pd.UpVotes DESC;
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY COUNT(c.Id) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    GROUP BY 
        p.Id, p.PostTypeId
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id
),
PostDetails AS (
    SELECT 
        r.PostId,
        r.PostTypeId,
        r.CommentCount,
        r.UpVotes,
        r.DownVotes,
        u.AboutMe,
        ub.BadgeCount,
        ub.HighestBadgeClass,
        CASE 
            WHEN p.AcceptedAnswerId IS NULL THEN 'No Accepted Answer'
            ELSE 'Accepted Answer Exists'
        END AS AcceptedAnswerStatus
    FROM 
        RankedPosts r
    JOIN 
        Posts p ON p.Id = r.PostId
    JOIN 
        Users u ON u.Id = p.OwnerUserId
    LEFT JOIN 
        UserBadges ub ON ub.UserId = p.OwnerUserId
)
SELECT 
    pd.PostId,
    pd.PostTypeId,
    pd.CommentCount,
    pd.UpVotes,
    pd.DownVotes,
    pd.AboutMe,
    pd.BadgeCount,
    pd.HighestBadgeClass,
    pd.AcceptedAnswerStatus,
    CASE 
        WHEN pd.CommentCount > 10 THEN 'Highly Interactive'
        WHEN pd.UpVotes - pd.DownVotes > 0 THEN 'Positive Engagement'
        ELSE 'Low Engagement'
    END AS EngagementLevel,
    STRING_AGG(DISTINCT pt.Name, ', ') AS PostType
FROM 
    PostDetails pd
JOIN 
    PostTypes pt ON pt.Id = pd.PostTypeId
GROUP BY 
    pd.PostId, pd.PostTypeId, pd.CommentCount, pd.UpVotes, pd.DownVotes, 
    pd.AboutMe, pd.BadgeCount, pd.HighestBadgeClass, pd.AcceptedAnswerStatus
HAVING 
    pd.CommentCount > 5 AND (pd.UpVotes - pd.DownVotes) > 2
ORDER BY 
    pd.UpVotes DESC, pd.CommentCount DESC
LIMIT 100;

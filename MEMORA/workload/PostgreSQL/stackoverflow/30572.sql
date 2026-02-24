
WITH RECURSIVE PostHierarchy AS (
    SELECT 
        Id,
        Title,
        ParentId,
        0 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        ph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.ParentId = ph.Id
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 6 THEN 1 ELSE 0 END) AS CloseVotes,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATE '2024-10-01' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.OwnerUserId
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        u.DisplayName,
        ub.BadgeCount,
        SUM(ps.CommentCount) AS TotalComments,
        SUM(ps.UpVoteCount) AS TotalUpVotes,
        SUM(ps.DownVoteCount) AS TotalDownVotes,
        SUM(ps.CloseVotes) AS TotalCloseVotes
    FROM 
        Users u
    JOIN 
        UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN 
        PostStats ps ON u.Id = ps.PostId 
    GROUP BY 
        u.DisplayName, ub.BadgeCount
)

SELECT 
    T.DisplayName,
    T.BadgeCount,
    T.TotalComments,
    T.TotalUpVotes,
    T.TotalDownVotes,
    T.TotalCloseVotes,
    CASE 
        WHEN ROUND((T.TotalUpVotes - T.TotalDownVotes) * 1.0 / NULLIF(T.TotalUpVotes + T.TotalDownVotes, 0), 2) > 0 THEN 'Positive Engagement'
        WHEN ROUND((T.TotalUpVotes - T.TotalDownVotes) * 1.0 / NULLIF(T.TotalUpVotes + T.TotalDownVotes, 0), 2) < 0 THEN 'Negative Engagement'
        ELSE 'Neutral Engagement'
    END AS EngagementStatus
FROM 
    TopUsers T
ORDER BY 
    T.TotalUpVotes DESC, T.TotalComments DESC;

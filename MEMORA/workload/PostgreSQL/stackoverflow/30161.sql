WITH RECURSIVE UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(v.BountyAmount) AS TotalBounties,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY COUNT(DISTINCT p.Id) DESC) AS EngagementRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(p.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        AVG(COALESCE(c.Score, 0)) AS AvgCommentScore
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.AcceptedAnswerId
),
RecentBadges AS (
    SELECT 
        b.UserId,
        ARRAY_AGG(b.Name ORDER BY b.Date DESC) AS BadgeNames,
        COUNT(b.Id) AS TotalBadges
    FROM 
        Badges b
    WHERE 
        b.Date >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        b.UserId
)

SELECT 
    ue.UserId,
    ue.DisplayName,
    ue.PostCount,
    ue.TotalBounties,
    ue.TotalUpvotes,
    ue.TotalDownvotes,
    pd.PostId,
    pd.Title AS PostTitle,
    pd.CreationDate AS PostCreated,
    pd.CommentCount,
    pd.AvgCommentScore,
    rb.BadgeNames,
    rb.TotalBadges
FROM 
    UserEngagement ue
JOIN 
    PostDetails pd ON ue.UserId = pd.AcceptedAnswerId
LEFT JOIN 
    RecentBadges rb ON ue.UserId = rb.UserId
WHERE 
    ue.EngagementRank <= 10
ORDER BY 
    ue.TotalUpvotes DESC, 
    pd.CommentCount DESC;
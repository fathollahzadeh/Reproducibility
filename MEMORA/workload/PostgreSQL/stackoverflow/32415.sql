
WITH RecursivePostHistory AS (
    SELECT 
        ph.Id,
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        PostHistory ph
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        SUM(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS VoteCount,
        SUM(CASE WHEN b.UserId IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount,
        SUM(CASE WHEN c.UserId IS NOT NULL THEN 1 ELSE 0 END) AS CommentCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    GROUP BY 
        u.Id
),
TopEngagedUsers AS (
    SELECT 
        ue.UserId,
        ue.VoteCount,
        ue.BadgeCount,
        ue.CommentCount,
        DENSE_RANK() OVER (ORDER BY (ue.VoteCount + ue.BadgeCount + ue.CommentCount) DESC) AS EngagementRank
    FROM 
        UserEngagement ue
),
PopularPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        COUNT(c.Id) AS TotalComments
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= (TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days')
    GROUP BY 
        p.Id, p.Title
    HAVING 
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) > 10
)
SELECT 
    pu.UserId,
    pu.VoteCount,
    pu.BadgeCount,
    pu.CommentCount,
    pp.PostId,
    pp.Title AS PopularPostTitle,
    pp.TotalUpVotes,
    pp.TotalComments,
    COALESCE(rph.Comment, 'No Comment') AS LastEditComment
FROM 
    TopEngagedUsers pu
JOIN 
    PostLinks pl ON pu.UserId = pl.PostId
JOIN 
    PopularPosts pp ON pp.PostId = pl.RelatedPostId
LEFT JOIN 
    RecursivePostHistory rph ON pp.PostId = rph.PostId AND rph.rn = 1
ORDER BY 
    pu.EngagementRank, pp.TotalUpVotes DESC;

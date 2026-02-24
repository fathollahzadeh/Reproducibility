
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COUNT(DISTINCT b.Id) AS TotalBadges,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS TotalUpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS TotalDownVotes,
        COUNT(CASE WHEN v.VoteTypeId = 1 THEN 1 END) AS TotalAccepted
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT
    ua.UserId,
    ua.DisplayName,
    ua.TotalPosts,
    ua.TotalComments,
    ua.TotalBadges,
    ua.TotalBounty,
    ua.TotalUpVotes,
    ua.TotalDownVotes,
    ua.TotalAccepted
FROM
    UserActivity ua
ORDER BY
    ua.TotalPosts DESC,
    ua.TotalComments DESC;

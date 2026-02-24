WITH UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        COUNT(c.Id) AS TotalComments,
        COUNT(DISTINCT b.Id) AS TotalBadges,
        SUM(v.BountyAmount) AS TotalBounty 
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
FilteredEngagement AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY TotalPosts DESC) AS EngagementRank
    FROM 
        UserEngagement
)
SELECT 
    fe.DisplayName,
    fe.TotalPosts,
    fe.Questions,
    fe.Answers,
    fe.TotalComments,
    fe.TotalBadges,
    fe.TotalBounty
FROM 
    FilteredEngagement fe
WHERE 
    fe.EngagementRank <= 10
ORDER BY 
    fe.EngagementRank;

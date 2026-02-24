
WITH PostCounts AS (
    SELECT 
        PostTypeId, 
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers
    FROM 
        Posts
    GROUP BY 
        PostTypeId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS TotalBadges,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBountyAmount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(ph.Id) AS RevisionCount,
        MAX(ph.CreationDate) AS LastRevisionDate
    FROM 
        PostHistory ph
    INNER JOIN 
        Posts p ON ph.PostId = p.Id
    GROUP BY 
        p.Id
)
SELECT 
    pc.PostTypeId,
    pc.TotalPosts,
    pc.TotalQuestions,
    pc.TotalAnswers,
    us.UserId,
    us.DisplayName,
    us.TotalBadges,
    us.TotalBountyAmount,
    phs.RevisionCount,
    phs.LastRevisionDate
FROM 
    PostCounts pc
JOIN 
    UserStats us ON us.UserId IS NOT NULL
JOIN 
    PostHistoryStats phs ON phs.PostId = pc.PostTypeId
ORDER BY 
    pc.TotalPosts DESC, us.TotalBadges DESC;

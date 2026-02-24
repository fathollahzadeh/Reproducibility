WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(p.Score) AS AverageScore,
        DENSE_RANK() OVER (ORDER BY SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) DESC) AS Rank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
ClosedPosts AS (
    SELECT 
        p.OwnerUserId,
        COUNT(ph.PostId) AS TotalClosedPosts,
        STRING_AGG(DISTINCT c.Name, ', ') AS ClosedReasonTypes
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10 
    LEFT JOIN 
        CloseReasonTypes c ON c.Id::text = ph.Comment 
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.TotalPosts,
    ua.TotalAnswers,
    ua.AverageScore,
    COALESCE(cp.TotalClosedPosts, 0) AS TotalClosedPosts,
    COALESCE(cp.ClosedReasonTypes, 'No reasons') AS ClosedReasonTypes
FROM 
    UserActivity ua
LEFT JOIN 
    ClosedPosts cp ON ua.UserId = cp.OwnerUserId
WHERE 
    ua.Rank <= 10
ORDER BY 
    ua.AverageScore DESC, ua.TotalPosts DESC;
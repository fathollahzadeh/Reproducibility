
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 1 THEN p.Score ELSE 0 END) AS TotalQuestionScore,
        AVG(u.Reputation) OVER (PARTITION BY u.Location) AS AvgReputationByLocation
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Location
),
PostLinksCounts AS (
    SELECT 
        pl.PostId,
        COUNT(pl.RelatedPostId) AS LinkCount
    FROM 
        PostLinks pl
    GROUP BY 
        pl.PostId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.UserDisplayName,
        ph.Comment
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
),
PostDetails AS (
    SELECT 
        p.Id,
        p.Title,
        COALESCE(pl.LinkCount, 0) AS LinkCount,
        ph.CreationDate AS ClosedDate,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        PostLinksCounts pl ON p.Id = pl.PostId
    LEFT JOIN 
        ClosedPosts ph ON p.Id = ph.PostId
)

SELECT 
    ups.DisplayName,
    ups.TotalPosts,
    ups.TotalAnswers,
    ups.TotalQuestionScore,
    ups.AvgReputationByLocation,
    pd.Title,
    pd.LinkCount,
    pd.ClosedDate,
    CASE 
        WHEN pd.ClosedDate IS NOT NULL THEN 'Yes' 
        ELSE 'No' 
    END AS IsClosed
FROM 
    UserPostStats ups
JOIN 
    PostDetails pd ON ups.UserId = pd.OwnerUserId
WHERE 
    ups.TotalPosts > 10 
    AND ups.AvgReputationByLocation IS NOT NULL
ORDER BY 
    ups.TotalQuestionScore DESC, 
    ups.TotalAnswers DESC;

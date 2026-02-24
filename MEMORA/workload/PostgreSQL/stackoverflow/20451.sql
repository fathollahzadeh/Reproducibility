
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties,
        LEAD(u.CreationDate) OVER (ORDER BY u.CreationDate) AS NextUserCreationDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostEngagement AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        DATE_PART('day', TIMESTAMP '2024-10-01 12:34:56' - p.CreationDate) AS AgeInDays,
        COUNT(DISTINCT c.Id) AS CommentCount, 
        p.AcceptedAnswerId IS NOT NULL AS HasAcceptedAnswer
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate, p.AcceptedAnswerId
),
ClosedPostReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT crt.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes crt ON ph.Comment::INTEGER = crt.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)
    GROUP BY 
        ph.PostId
),
UserPostStats AS (
    SELECT 
        ua.DisplayName,
        ua.TotalPosts,
        ua.TotalComments,
        COALESCE(pe.PostId, NULL) AS FeaturedPostId,
        COALESCE(pe.Title, 'No Posts') AS FeaturedPostTitle,
        COALESCE(pe.Score, 0) AS FeaturedPostScore,
        COALESCE(pe.CommentCount, 0) AS FeaturedPostComments,
        COALESCE(cr.CloseReasons, 'No Closure') AS CloseReasons
    FROM 
        UserActivity ua
    LEFT JOIN 
        PostEngagement pe ON ua.UserId = (SELECT OwnerUserId FROM Posts ORDER BY RANDOM() LIMIT 1)
    LEFT JOIN 
        ClosedPostReasons cr ON pe.PostId = cr.PostId
)
SELECT 
    u.DisplayName,
    u.TotalPosts,
    u.TotalComments,
    u.FeaturedPostTitle,
    u.FeaturedPostScore,
    u.FeaturedPostComments,
    u.CloseReasons,
    CASE 
        WHEN u.CloseReasons IS NULL THEN 'Active' 
        ELSE 'Closed' 
    END AS PostStatus,
    CASE 
        WHEN u.TotalPosts = 0 AND u.TotalComments = 0 THEN 'Inactive' 
        WHEN u.TotalPosts < 5 THEN 'Novice' 
        ELSE 'Veteran' 
    END AS UserTier
FROM 
    UserPostStats u
WHERE 
    u.TotalPosts > 0 OR u.TotalComments > 0
ORDER BY 
    u.TotalPosts DESC, u.TotalComments DESC
LIMIT 50;

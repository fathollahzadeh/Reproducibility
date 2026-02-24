
WITH RecursivePostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.PostHistoryTypeId,
        ph.UserId,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS RowNum
    FROM 
        PostHistory ph
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
        AVG(COALESCE(v.BountyAmount, 0)) AS AvgBountyPerUser
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
ClosedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        ph.UserId AS CloserId,
        ph.Comment AS CloseReason,
        COUNT(DISTINCT c.Id) AS NumberOfComments
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, ph.UserId, ph.Comment, p.Title
),
UserStats AS (
    SELECT 
        ue.UserId,
        ue.TotalPosts,
        ue.TotalComments,
        ue.TotalBounty,
        ue.AvgBountyPerUser,
        cp.Title,
        cp.CloseReason,
        cp.NumberOfComments
    FROM 
        UserEngagement ue
    LEFT JOIN 
        ClosedPosts cp ON ue.UserId = cp.CloserId
)
SELECT 
    u.DisplayName,
    u.Reputation,
    COALESCE(us.TotalPosts, 0) AS TotalPosts,
    COALESCE(us.TotalComments, 0) AS TotalComments,
    COALESCE(us.TotalBounty, 0) AS TotalBounty,
    COALESCE(us.AvgBountyPerUser, 0) AS AvgBountyPerUser,
    cp.Title,
    cp.CloseReason,
    cp.NumberOfComments
FROM 
    Users u
LEFT JOIN 
    UserStats us ON u.Id = us.UserId
LEFT JOIN 
    ClosedPosts cp ON us.Title = cp.Title
WHERE 
    u.Reputation >= 1000
    AND (COALESCE(us.TotalPosts, 0) > 5 OR COALESCE(us.TotalComments, 0) > 10)
    AND (SELECT COUNT(*) 
         FROM PostHistory ph 
         WHERE ph.UserId = u.Id 
           AND ph.PostHistoryTypeId IN (10, 11) 
           AND ph.CreationDate > (TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '6 months')) >= 1
ORDER BY 
    u.Reputation DESC,
    COALESCE(us.TotalPosts, 0) DESC,
    COALESCE(us.TotalBounty, 0) DESC;

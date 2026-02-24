
WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ParentId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ParentId,
        ph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.ParentId = ph.PostId
), UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCount,
        SUM(v.BountyAmount) AS TotalBounty,
        AVG(p.Score) AS AverageScore,
        DENSE_RANK() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS Rank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId 
    GROUP BY 
        u.Id, u.DisplayName
), ClosedPostReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT ctr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes ctr ON CAST(ph.Comment AS INTEGER) = ctr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  
    GROUP BY 
        ph.PostId
), PostsWithDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(ph.Level, 0) AS PostLevel,
        u.DisplayName AS OwnerDisplayName,
        ca.Title AS AcceptedAnswerTitle,
        cr.CloseReasons,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Body
    FROM 
        Posts p
    LEFT JOIN 
        PostHierarchy ph ON p.Id = ph.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts ca ON p.AcceptedAnswerId = ca.Id  
    LEFT JOIN 
        ClosedPostReasons cr ON p.Id = cr.PostId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'  
)
SELECT 
    pwd.PostId,
    pwd.Title,
    pwd.OwnerDisplayName,
    pwd.ViewCount,
    pwd.Score,
    COALESCE(pwd.CloseReasons, 'No close reason') AS CloseReason,
    pwd.PostLevel,
    ua.PostsCount,
    ua.TotalBounty,
    ua.AverageScore,
    ua.Rank
FROM 
    PostsWithDetails pwd
JOIN 
    UserActivity ua ON pwd.OwnerDisplayName = ua.DisplayName
ORDER BY 
    pwd.Score DESC,
    ua.TotalBounty DESC
LIMIT 100;

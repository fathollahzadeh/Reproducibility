WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS TotalVotes,
        AVG(EXTRACT(EPOCH FROM (cast('2024-10-01 12:34:56' as timestamp) - u.CreationDate))) AS AvgAccountAgeInSec
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

RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment,
        p.Title,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
)

SELECT 
    ua.DisplayName,
    ua.TotalPosts,
    ua.TotalComments,
    ua.TotalVotes,
    ua.AvgAccountAgeInSec,
    rp.Title,
    rp.Comment,
    rp.CreationDate
FROM 
    UserActivity ua
LEFT JOIN 
    RecentPostHistory rp ON ua.UserId = rp.OwnerUserId AND rp.rn = 1
WHERE 
    ua.TotalPosts > 10 OR ua.TotalComments > 50
ORDER BY 
    ua.TotalVotes DESC,
    ua.TotalPosts ASC;

WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownvotes,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 100 
    GROUP BY 
        u.Id, u.DisplayName
), 
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '1 year'
), 
RecentPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.Score,
        ps.ViewCount,
        ps.AnswerCount,
        ua.DisplayName AS OwnerName,
        ua.TotalUpvotes,
        ua.TotalDownvotes
    FROM 
        PostStats ps
    JOIN 
        UserActivity ua ON ps.PostId = ANY (SELECT Id FROM Posts WHERE OwnerUserId = ua.UserId)
    WHERE 
        ps.rn = 1 
    AND 
        ps.Score > 0 
)
SELECT 
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    COALESCE(rp.TotalUpvotes - rp.TotalDownvotes, 0) AS NetVotes,
    CASE 
        WHEN rp.TotalUpvotes > 3 THEN 'Active User'
        WHEN rp.TotalDownvotes > 3 THEN 'Content Issues'
        ELSE 'Moderate User'
    END AS UserActivityStatus,
    STRING_AGG(DISTINCT pt.Name, ', ') AS RelatedPostTypes
FROM 
    RecentPosts rp
LEFT JOIN 
    PostTypes pt ON pt.Id = (SELECT PostTypeId FROM Posts WHERE Id = rp.PostId)
GROUP BY 
    rp.Title, rp.Score, rp.ViewCount, rp.AnswerCount, rp.TotalUpvotes, rp.TotalDownvotes
ORDER BY 
    NetVotes DESC, rp.ViewCount DESC
LIMIT 10;

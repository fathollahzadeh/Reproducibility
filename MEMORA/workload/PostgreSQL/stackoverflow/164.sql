WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(v.BountyAmount) AS TotalBounties,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
    WHERE 
        u.Reputation > 0
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT ph.Id) AS CloseEvents,
        MAX(ph.CreationDate) AS LastClosed
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        p.Id
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.TotalPosts,
    us.QuestionCount,
    us.AnswerCount,
    us.TotalBounties,
    cp.CloseEvents,
    cp.LastClosed,
    CASE 
        WHEN cp.CloseEvents IS NOT NULL THEN 'Closed' 
        ELSE 'Active' 
    END AS PostStatus,
    CASE 
        WHEN us.Rank <= 10 THEN 'Top Contributor'
        ELSE 'Contributor'
    END AS UserLevel
FROM 
    UserStats us
LEFT JOIN 
    ClosedPosts cp ON us.UserId = cp.PostId
WHERE 
    us.TotalPosts > 5
ORDER BY 
    us.Rank, us.Reputation DESC
LIMIT 100;
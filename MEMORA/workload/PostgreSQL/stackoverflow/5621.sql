WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS Questions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS Answers,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.CreationDate
), 
PostHistoryCount AS (
    SELECT 
        p.Id AS PostId,
        COUNT(ph.Id) AS RevisionCount
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.CreationDate,
    us.TotalPosts,
    us.Questions,
    us.Answers,
    us.TotalScore,
    us.TotalBadges,
    COALESCE(phc.RevisionCount, 0) AS TotalRevisions
FROM 
    UserStats us
LEFT JOIN 
    PostHistoryCount phc ON us.UserId = phc.PostId
WHERE 
    us.Reputation > 1000
ORDER BY 
    us.Reputation DESC, us.TotalScore DESC
LIMIT 50;

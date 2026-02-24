WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        AVG(p.Score) AS AverageScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1 
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
ClosedQuestions AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.UserDisplayName,
        ph.Comment,
        ph.Text AS CloseReason
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId = 10 
),
MostActiveUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        COUNT(*) AS ActivityCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(*) > 10 
),
PostViewDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(c.UserDisplayName, 'Anonymous') AS CommentUser,
        c.Text AS Comment,
        p.ViewCount,
        p.CreationDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
)
SELECT 
    u.DisplayName,
    u.Reputation,
    us.QuestionCount,
    us.TotalViews,
    us.AverageScore,
    rp.Title AS BestPost,
    rp.CreationDate AS BestPostDate,
    cl.CloseReason,
    mv.ActivityCount
FROM 
    Users u
JOIN 
    UserStats us ON u.Id = us.UserId
JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId AND rp.Rank = 1 
LEFT JOIN 
    ClosedQuestions cl ON u.Id = (SELECT ph.UserId FROM PostHistory ph WHERE ph.PostId = cl.PostId LIMIT 1)
LEFT JOIN 
    MostActiveUsers mv ON u.Id = mv.Id
WHERE 
    us.QuestionCount > 5
ORDER BY 
    us.Reputation DESC, us.TotalViews DESC;

WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.AnswerCount,
        p.ViewCount,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
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
        u.Views,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.Views
),

TopPosters AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.TotalPosts,
        us.Views,
        ROW_NUMBER() OVER (ORDER BY us.Reputation DESC) AS Ranking
    FROM 
        UserStats us
    WHERE 
        us.TotalPosts > 0
),

ClusteredHistory AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MIN(ph.CreationDate) AS FirstEditDate,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5) 
    GROUP BY 
        ph.PostId
)

SELECT 
    up.UserId,
    up.DisplayName,
    up.Reputation,
    up.TotalPosts,
    up.Views,
    COALESCE(rp.PostId, 0) AS TopPostId,
    COALESCE(rp.Title, 'No Posts') AS TopPostTitle,
    COALESCE(rp.Score, 0) AS TopPostScore,
    COALESCE(ch.EditCount, 0) AS TotalEdits,
    COALESCE(ch.FirstEditDate, '1970-01-01') AS FirstEditDate,
    COALESCE(ch.LastEditDate, '1970-01-01') AS LastEditDate
FROM 
    TopPosters up
LEFT JOIN 
    RankedPosts rp ON up.UserId = rp.OwnerUserId AND rp.PostRank = 1
LEFT JOIN 
    ClusteredHistory ch ON rp.PostId = ch.PostId
WHERE 
    up.Ranking <= 10 
ORDER BY 
    up.Reputation DESC;
